import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var todaySleep: SleepRecord?
    @Published var weeklySleep: [SleepRecord] = []
    @Published var isLoading = false

    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else { return }

        let typesToRead: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    func fetchTodaySleep() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = now

        do {
            let record = try await fetchSleep(from: startOfToday, to: endOfToday)
            todaySleep = record
        } catch {
            print("Failed to fetch today's sleep: \(error)")
        }
    }

    func fetchWeeklySleep() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()
        var records: [SleepRecord] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay: Date
            if dayOffset == 0 {
                endOfDay = now
            } else {
                endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            }

            do {
                if let record = try await fetchSleep(from: startOfDay, to: endOfDay) {
                    records.append(record)
                }
            } catch {
                print("Failed to fetch sleep for \(date): \(error)")
            }
        }

        weeklySleep = records.sorted { $0.date < $1.date }
    }

    private func fetchSleep(from startDate: Date, to endDate: Date) async throws -> SleepRecord? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let record = self.processSleepSamples(samples, date: startDate)
                continuation.resume(returning: record)
            }

            self.healthStore.execute(query)
        }
    }

    private func processSleepSamples(_ samples: [HKCategorySample], date: Date) -> SleepRecord {
        var stages: [SleepStage] = []

        let sleepPhaseMap: [Int: SleepStageType] = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: .light,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue: .light,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue: .deep,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue: .rem,
            HKCategoryValueSleepAnalysis.awake.rawValue: .awake
        ]

        for sample in samples {
            let value = sample.value
            let stageType: SleepStageType

            if let mapped = sleepPhaseMap[value] {
                stageType = mapped
            } else if #available(iOS 26.0, *) {
                if value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    stageType = .light
                } else {
                    stageType = .light
                }
            } else {
                stageType = .light
            }

            let stage = SleepStage(
                type: stageType,
                startDate: sample.startDate,
                endDate: sample.endDate
            )
            stages.append(stage)
        }

        stages.sort { $0.startDate < $1.startDate }

        let totalDuration = stages.reduce(0) { $0 + $1.duration }

        let fellAsleepTime: Date
        if let first = stages.first {
            fellAsleepTime = first.startDate
        } else {
            fellAsleepTime = date
        }

        let wokeUpTime: Date
        if let last = stages.last {
            wokeUpTime = last.endDate
        } else {
            wokeUpTime = date
        }

        let score = calculateSleepScore(stages: stages, totalDuration: totalDuration)

        var heartRateMin: Int?
        var heartRateMax: Int?
        var heartRateAvg: Int?

        Task {
            if let hrData = try? await fetchHeartRateData(from: fellAsleepTime, to: wokeUpTime) {
                heartRateMin = hrData.min
                heartRateMax = hrData.max
                heartRateAvg = hrData.avg
            }
        }

        return SleepRecord(
            date: date,
            totalDuration: totalDuration,
            fellAsleepTime: fellAsleepTime,
            wokeUpTime: wokeUpTime,
            stages: stages,
            score: score,
            heartRateMin: heartRateMin,
            heartRateMax: heartRateMax,
            heartRateAvg: heartRateAvg,
            insight: nil
        )
    }

    private func calculateSleepScore(stages: [SleepStage], totalDuration: TimeInterval) -> Int {
        let totalMinutes = totalDuration / 60
        guard totalMinutes > 0 else { return 0 }

        let deepMinutes = stages.filter { $0.type == .deep }.reduce(0) { $0 + $1.durationMinutes }
        let remMinutes = stages.filter { $0.type == .rem }.reduce(0) { $0 + $1.durationMinutes }
        let awakeMinutes = stages.filter { $0.type == .awake }.reduce(0) { $0 + $1.durationMinutes }

        let deepRatio = Double(deepMinutes) / totalMinutes
        let remRatio = Double(remMinutes) / totalMinutes
        let awakeRatio = Double(awakeMinutes) / totalMinutes

        let durationScore: Double
        if totalMinutes >= 420 && totalMinutes <= 540 {
            durationScore = 100
        } else if totalMinutes < 420 {
            durationScore = max(0, Double(totalMinutes) / 420.0 * 100)
        } else {
            durationScore = max(0, 100 - (Double(totalMinutes) - 540) / 60.0 * 20)
        }

        let deepScore = min(100, deepRatio * 400)
        let remScore = min(100, remRatio * 300)
        let awakePenalty = awakeRatio * 150

        let score = Int(durationScore * 0.3 + deepScore * 0.3 + remScore * 0.25 + (100 - awakePenalty) * 0.15)
        return min(100, max(0, score))
    }

    private func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> (min: Int, max: Int, avg: Int)? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                let values = quantitySamples.map { Int($0.quantity.doubleValue(for: unit)) }

                let minVal = values.min() ?? 0
                let maxVal = values.max() ?? 0
                let avgVal = values.reduce(0, +) / values.count

                continuation.resume(returning: (min: minVal, max: maxVal, avg: avgVal))
            }

            self.healthStore.execute(query)
        }
    }
}
