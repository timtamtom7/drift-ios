import Foundation
import HealthKit

final class HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    // MARK: - Sleep Data

    func getLastNightSleep() async throws -> SleepData {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        // Get sleep samples from last night (6 PM to 10 AM next day)
        let calendar = Calendar.current
        let now = Date()
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let startOfSleepWindow = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: startOfYesterday)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfSleepWindow,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sleepData = self.processSleepSamples(samples ?? [])
                continuation.resume(returning: sleepData)
            }

            self.healthStore.execute(query)
        }
    }

    func getSleepHistory(days: Int = 7) async throws -> [SleepData] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sleepDataArray = self.aggregateSleepByNight(samples ?? [])
                continuation.resume(returning: sleepDataArray)
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Movement Data (for sleep phase detection)

    func getMovementData(from startDate: Date, to endDate: Date) async throws -> [Double] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(minute: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                var movementValues: [Double] = []
                results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    movementValues.append(steps)
                }

                continuation.resume(returning: movementValues)
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Private Helpers

    private func processSleepSamples(_ samples: [HKSample]) -> SleepData {
        var inBedDuration: TimeInterval = 0
        var asleepDuration: TimeInterval = 0
        var deepSleepDuration: TimeInterval = 0
        var remSleepDuration: TimeInterval = 0
        var awakeDuration: TimeInterval = 0

        for sample in samples {
            guard let categorySample = sample as? HKCategorySample else { continue }

            let duration = categorySample.endDate.timeIntervalSince(categorySample.startDate)

            switch categorySample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBedDuration += duration

            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                 HKCategoryValueSleepAnalysis.awake.rawValue:
                asleepDuration += duration
                awakeDuration += duration

            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                // Core sleep (between light and deep)
                asleepDuration += duration

            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                asleepDuration += duration
                deepSleepDuration += duration

            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                asleepDuration += duration
                remSleepDuration += duration

            default:
                break
            }
        }

        let sleepScore = calculateSleepScore(
            total: asleepDuration,
            deep: deepSleepDuration,
            rem: remSleepDuration,
            awake: awakeDuration
        )

        return SleepData(
            totalSleep: asleepDuration,
            deepSleep: deepSleepDuration,
            remSleep: remSleepDuration,
            awake: awakeDuration,
            sleepScore: sleepScore
        )
    }

    private func aggregateSleepByNight(_ samples: [HKSample]) -> [SleepData] {
        // Group samples by night (6 PM - 10 AM)
        let calendar = Calendar.current
        var nightBuckets: [String: [HKSample]] = [:]

        for sample in samples {
            let date = sample.startDate
            let hour = calendar.component(.hour, from: date)

            // Determine which "night" this belongs to
            let nightKey: String
            if hour >= 18 {
                // Evening of this day
                nightKey = calendar.startOfDay(for: date).timeIntervalSince1970.description
            } else {
                // Morning belongs to previous day's night
                let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
                nightKey = calendar.startOfDay(for: previousDay).timeIntervalSince1970.description
            }

            nightBuckets[nightKey, default: []].append(sample)
        }

        return nightBuckets.values.map { samples in
            processSleepSamples(samples)
        }.sorted { $0.totalSleep > $1.totalSleep }
    }

    private func calculateSleepScore(
        total: TimeInterval,
        deep: TimeInterval,
        rem: TimeInterval,
        awake: TimeInterval
    ) -> Int {
        // Score from 0-100 based on sleep quality metrics
        // Optimal: 7-9 hours total, 1-2 hours deep, 1.5-2.5 hours REM, minimal awake

        let optimalTotal = 8 * 3600 // 8 hours in seconds
        let optimalDeep = 1.5 * 3600
        let optimalRem = 2.0 * 3600

        var score: Double = 100.0

        // Total sleep score (40% weight)
        let totalDiff = abs(total - Double(optimalTotal))
        let totalPenalty = min(Double(40), (totalDiff / 3600) * 5) // -5 points per 1h deviation
        score -= totalPenalty

        // Deep sleep score (25% weight)
        if deep < optimalDeep {
            let deepPenalty = min(Double(25), ((optimalDeep - deep) / 3600) * 15)
            score -= deepPenalty
        }

        // REM sleep score (25% weight)
        if rem < optimalRem {
            let remPenalty = min(Double(25), ((optimalRem - rem) / 3600) * 12)
            score -= remPenalty
        }

        // Awake time penalty (10% weight)
        let awakePenalty = min(Double(10), (awake / 3600) * 20)
        score -= awakePenalty

        return max(0, min(100, Int(score)))
    }
}

// MARK: - Data Models

extension HealthKitService {
    struct SleepData {
        let totalSleep: TimeInterval
        let deepSleep: TimeInterval
        let remSleep: TimeInterval
        let awake: TimeInterval
        let sleepScore: Int

        var totalSleepFormatted: String {
            let hours = Int(totalSleep) / 3600
            let minutes = (Int(totalSleep) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

        var deepSleepFormatted: String {
            let hours = Int(deepSleep) / 3600
            let minutes = (Int(deepSleep) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

        var remSleepFormatted: String {
            let hours = Int(remSleep) / 3600
            let minutes = (Int(remSleep) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

        var awakeFormatted: String {
            let minutes = Int(awake) / 60
            return "\(minutes)m"
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .queryFailed(let message):
            return "HealthKit query failed: \(message)"
        }
    }
}
