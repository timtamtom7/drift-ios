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
    @Published var hrvDataUnavailable = false
    @Published var respiratoryDataUnavailable = false

    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else { return }

        let typesToRead: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
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

    func fetchSleepForDate(startOfDay: Date, endOfDay: Date) async throws -> SleepRecord? {
        return try await fetchSleep(from: startOfDay, to: endOfDay)
    }

    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> HRVData? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HRVData?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit = HKUnit.secondUnit(with: .milli)
                let values = quantitySamples.map { $0.quantity.doubleValue(for: unit) }

                let minVal = values.min() ?? 0
                let maxVal = values.max() ?? 0
                let avgVal = values.reduce(0, +) / Double(values.count)

                continuation.resume(returning: HRVData(
                    min: minVal,
                    max: maxVal,
                    avg: avgVal,
                    sampleCount: values.count
                ))
            }

            self.healthStore.execute(query)
        }
    }

    func fetchRespiratoryRate(from startDate: Date, to endDate: Date) async throws -> RespiratoryData? {
        guard let respType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RespiratoryData?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: respType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
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
                let values = quantitySamples.map { $0.quantity.doubleValue(for: unit) }

                let minVal = values.min() ?? 0
                let maxVal = values.max() ?? 0
                let avgVal = values.reduce(0, +) / Double(values.count)

                continuation.resume(returning: RespiratoryData(min: minVal, max: maxVal, avg: avgVal))
            }

            self.healthStore.execute(query)
        }
    }

    func fetchSpO2Data(from startDate: Date, to endDate: Date) async throws -> SpO2Data? {
        guard let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SpO2Data?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: spo2Type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let percentValues = quantitySamples.map { $0.quantity.doubleValue(for: .percent()) * 100 }

                let minVal = percentValues.min() ?? 0
                let maxVal = percentValues.max() ?? 0
                let avgVal = percentValues.reduce(0, +) / Double(percentValues.count)

                let dropsBelow90 = percentValues.filter { $0 < 90 }.count

                continuation.resume(returning: SpO2Data(min: minVal, max: maxVal, avg: avgVal, dropsBelow90Percent: dropsBelow90))
            }

            self.healthStore.execute(query)
        }
    }

    func fetchWristTemperature(from startDate: Date, to endDate: Date) async throws -> TemperatureData? {
        guard let tempType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TemperatureData?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: tempType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit = HKUnit.degreeFahrenheit()
                let values = quantitySamples.map { $0.quantity.doubleValue(for: unit) }

                let minVal = values.min() ?? 0
                let maxVal = values.max() ?? 0
                let avgVal = values.reduce(0, +) / Double(values.count)

                continuation.resume(returning: TemperatureData(min: minVal, max: maxVal, avg: avgVal))
            }

            self.healthStore.execute(query)
        }
    }

    func fetchCaffeineIntake(for date: Date) async throws -> Double? {
        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: caffeineType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil as Double?)
                    return
                }

                let unit = HKUnit.gramUnit(with: .milli)
                let total = quantitySamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
                continuation.resume(returning: total)
            }

            self.healthStore.execute(query)
        }
    }

    func fetchExerciseMinutes(for date: Date) async throws -> Double? {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: activeEnergyType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil as Double?)
                    return
                }

                let unit = HKUnit.kilocalorie()
                let totalKCAL = quantitySamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
                let exerciseMinutes = totalKCAL / 10.0
                continuation.resume(returning: exerciseMinutes)
            }

            self.healthStore.execute(query)
        }
    }

    func fetchMindfulMinutes(for date: Date) async throws -> Double? {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: nil as Double?)
                    return
                }

                let totalMinutes = categorySamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                }

                continuation.resume(returning: totalMinutes)
            }

            self.healthStore.execute(query)
        }
    }

    private func fetchSleep(from startDate: Date, to endDate: Date) async throws -> SleepRecord? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let samples: [HKCategorySample]? = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample]?, Error>) in
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
                continuation.resume(returning: samples)
            }
            self.healthStore.execute(query)
        }

        guard let samples = samples, !samples.isEmpty else { return nil }

        let stages = processStages(from: samples)
        let totalDuration = stages.reduce(0) { $0 + $1.duration }
        let fellAsleepTime = stages.first?.startDate ?? startDate
        let wokeUpTime = stages.last?.endDate ?? endDate
        let score = calculateSleepScore(stages: stages, totalDuration: totalDuration)

        async let heartRateTask: (min: Int, max: Int, avg: Int)? = fetchHeartRateData(from: fellAsleepTime, to: wokeUpTime)
        async let hrvTask: HRVData? = fetchHRVData(from: fellAsleepTime, to: wokeUpTime)
        async let respTask: RespiratoryData? = fetchRespiratoryRate(from: fellAsleepTime, to: wokeUpTime)
        async let spo2Task: SpO2Data? = fetchSpO2Data(from: fellAsleepTime, to: wokeUpTime)
        async let tempTask: TemperatureData? = fetchWristTemperature(from: fellAsleepTime, to: wokeUpTime)
        async let caffeineTask: Double? = fetchCaffeineIntake(for: startDate)
        async let exerciseTask: Double? = fetchExerciseMinutes(for: startDate)
        async let mindfulTask: Double? = fetchMindfulMinutes(for: startDate)

        let (heartRateResult, hrvResult, respResult, spo2Result, tempResult, caffeineResult, exerciseResult, mindfulResult) =
            await (try? await heartRateTask, try? await hrvTask, try? await respTask, try? await spo2Task,
                   try? await tempTask, try? await caffeineTask, try? await exerciseTask, try? await mindfulTask)

        if hrvResult == nil { hrvDataUnavailable = true }
        if respResult == nil && spo2Result == nil { respiratoryDataUnavailable = true }

        return SleepRecord(
            date: startDate,
            totalDuration: totalDuration,
            fellAsleepTime: fellAsleepTime,
            wokeUpTime: wokeUpTime,
            stages: stages,
            score: score,
            heartRateMin: heartRateResult?.min,
            heartRateMax: heartRateResult?.max,
            heartRateAvg: heartRateResult?.avg,
            hrvAvg: hrvResult?.avg,
            respiratoryRateAvg: respResult?.avg,
            spo2Avg: spo2Result?.avg,
            spo2DropsBelow90: spo2Result?.dropsBelow90Percent,
            wristTempAvg: tempResult?.avg,
            caffeineMg: caffeineResult,
            exerciseMinutes: exerciseResult,
            mindfulMinutes: mindfulResult
        )
    }

    private func processStages(from samples: [HKCategorySample]) -> [SleepStage] {
        let sleepPhaseMap: [Int: SleepStageType] = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: .light,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue: .light,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue: .deep,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue: .rem,
            HKCategoryValueSleepAnalysis.awake.rawValue: .awake
        ]

        var stages: [SleepStage] = []
        for sample in samples {
            let stageType: SleepStageType
            if let mapped = sleepPhaseMap[sample.value] {
                stageType = mapped
            } else {
                stageType = .light
            }
            stages.append(SleepStage(
                type: stageType,
                startDate: sample.startDate,
                endDate: sample.endDate
            ))
        }
        return stages.sorted { $0.startDate < $1.startDate }
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

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(min: Int, max: Int, avg: Int)?, Error>) in
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

// MARK: - Health Data Types

struct HRVData {
    let min: Double
    let max: Double
    let avg: Double
    let sampleCount: Int
}

struct RespiratoryData {
    let min: Double
    let max: Double
    let avg: Double
}

struct SpO2Data {
    let min: Double
    let max: Double
    let avg: Double
    let dropsBelow90Percent: Int
}

struct TemperatureData {
    let min: Double
    let max: Double
    let avg: Double
}
