import Foundation
import HealthKit

/// Apple Health Export Service
/// Exports Drift sleep data to Apple Health and provides data portability.
@MainActor
class HealthExportService: ObservableObject {
    @Published var isExporting = false
    @Published var lastExportDate: Date?
    @Published var exportedRecordsCount = 0
    @Published var error: String?

    private let healthStore = HKHealthStore()

    /// Export a sleep record to Apple Health
    /// Writes sleep analysis samples for each sleep stage
    func exportSleepRecord(_ record: SleepRecord) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            error = "HealthKit is not available on this device."
            return false
        }

        isExporting = true
        error = nil
        defer { isExporting = false }

        do {
            // Write sleep analysis samples for each stage
            for stage in record.stages {
                guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
                    error = "Sleep analysis type unavailable."
                    return false
                }

                // Map our stage type to HKCategoryValueSleepAnalysis
                let hkSleepValue: HKCategoryValueSleepAnalysis
                switch stage.type {
                case .deep:
                    hkSleepValue = .asleepDeep
                case .rem:
                    hkSleepValue = .asleepREM
                case .light:
                    hkSleepValue = .asleepCore
                case .awake:
                    hkSleepValue = .awake
                }

                let sleepSample = HKCategorySample(
                    type: sleepType,
                    value: hkSleepValue.rawValue,
                    start: stage.startDate,
                    end: stage.endDate
                )

                try await healthStore.save(sleepSample)
            }

            // Optionally write heart rate data if available
            if record.heartRateAvg != nil {
                try await exportHeartRateSamples(for: record)
            }

            // Write HRV data if available
            if let hrv = record.hrvAvg {
                try await exportHRVData(for: record, hrvValue: hrv)
            }

            lastExportDate = Date()
            return true
        } catch {
            self.error = "Export failed: \(error.localizedDescription)"
            return false
        }
    }

    /// Export multiple sleep records to Apple Health
    func exportSleepRecords(_ records: [SleepRecord]) async -> Int {
        var exportedCount = 0

        for record in records {
            if await exportSleepRecord(record) {
                exportedCount += 1
            }
        }

        exportedRecordsCount = exportedCount
        return exportedCount
    }

    /// Export all Drift sleep data from local database to Apple Health
    func exportAllFromDatabase() async -> Int {
        let databaseService = DatabaseService()
        let records = (try? databaseService.fetchAllRecords()) ?? []
        return await exportSleepRecords(records)
    }

    /// Export sleep data for a specific date range
    func exportDateRange(from startDate: Date, to endDate: Date) async -> Int {
        let databaseService = DatabaseService()
        let calendar = Calendar.current
        let allRecords = (try? databaseService.fetchAllRecords()) ?? []

        let filteredRecords = allRecords.filter { record in
            record.date >= calendar.startOfDay(for: startDate) &&
            record.date <= calendar.startOfDay(for: endDate)
        }

        return await exportSleepRecords(filteredRecords)
    }

    // MARK: - Private Helpers

    private func exportHeartRateSamples(for record: SleepRecord) async throws {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let avgHR = record.heartRateAvg else { return }

        let unit = HKUnit.count().unitDivided(by: .minute())

        // Write a single sample representing average heart rate during sleep
        // In production, you'd iterate over actual HR samples from HealthKit
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: HKQuantity(unit: unit, doubleValue: Double(avgHR)),
            start: record.fellAsleepTime,
            end: record.wokeUpTime
        )

        try await healthStore.save(heartRateSample)
    }

    private func exportHRVData(for record: SleepRecord, hrvValue: Double) async throws {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }

        let unit = HKUnit.secondUnit(with: .milli)

        let hrvSample = HKQuantitySample(
            type: hrvType,
            quantity: HKQuantity(unit: unit, doubleValue: hrvValue),
            start: record.fellAsleepTime,
            end: record.wokeUpTime
        )

        try await healthStore.save(hrvSample)
    }

    // MARK: - Data Export (JSON/CSV)

    /// Export all sleep data as a JSON file
    func exportAsJSON() async throws -> URL {
        let databaseService = DatabaseService()
        let records = (try? databaseService.fetchAllRecords()) ?? []

        let exportData = SleepExportData(
            exportDate: Date(),
            appVersion: "1.0.0",
            records: records
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportData)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "drift_export_\(ISO8601DateFormatter().string(from: Date())).json"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try jsonData.write(to: fileURL)
        return fileURL
    }

    /// Export sleep data as a CSV file
    func exportAsCSV() async throws -> URL {
        let databaseService = DatabaseService()
        let records = (try? databaseService.fetchAllRecords()) ?? []

        var csvLines: [String] = []

        // Header
        csvLines.append([
            "date",
            "total_hours",
            "score",
            "deep_minutes",
            "rem_minutes",
            "light_minutes",
            "awake_minutes",
            "hrv_avg",
            "heart_rate_avg",
            "heart_rate_min",
            "heart_rate_max",
            "respiratory_rate_avg",
            "spo2_avg",
            "caffeine_mg",
            "exercise_minutes"
        ].joined(separator: ","))

        // Data rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for record in records {
            let hrvStr: String = record.hrvAvg.map { String(format: "%.1f", $0) } ?? ""
            let hrAvgStr: String = record.heartRateAvg.map { String($0) } ?? ""
            let hrMinStr: String = record.heartRateMin.map { String($0) } ?? ""
            let hrMaxStr: String = record.heartRateMax.map { String($0) } ?? ""
            let respStr: String = record.respiratoryRateAvg.map { String(format: "%.1f", $0) } ?? ""
            let spo2Str: String = record.spo2Avg.map { String(format: "%.1f", $0) } ?? ""
            let caffeineStr: String = record.caffeineMg.map { String(format: "%.1f", $0) } ?? ""
            let exerciseStr: String = record.exerciseMinutes.map { String(format: "%.1f", $0) } ?? ""

            let row: String = [
                dateFormatter.string(from: record.date),
                String(format: "%.1f", record.totalHours),
                String(record.score),
                String(record.deepSleepMinutes),
                String(record.remSleepMinutes),
                String(record.lightSleepMinutes),
                String(record.awakeMinutes),
                hrvStr,
                hrAvgStr,
                hrMinStr,
                hrMaxStr,
                respStr,
                spo2Str,
                caffeineStr,
                exerciseStr
            ].joined(separator: ",")

            csvLines.append(row)
        }

        let csvContent = csvLines.joined(separator: "\n")

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "drift_export_\(ISO8601DateFormatter().string(from: Date())).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    /// Generate a shareable export URL for JSON or CSV
    func getExportURL(format: ExportFormat) async throws -> URL {
        switch format {
        case .json:
            return try await exportAsJSON()
        case .csv:
            return try await exportAsCSV()
        }
    }

    enum ExportFormat {
        case json
        case csv
    }
}

// MARK: - Export Data Models

struct SleepExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let records: [SleepRecord]
}

// MARK: - SubscriptionManager

/// Manages subscription tier enforcement for Drift freemium model
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var currentTier: PricingTier = .free

    private let userDefaultsKey = "selectedPlan"
    private let historyLimitKey = "historyLimitDays"

    init() {
        loadTier()
    }

    private func loadTier() {
        if let savedTier = UserDefaults.standard.string(forKey: userDefaultsKey),
           let tier = PricingTier(rawValue: savedTier) {
            currentTier = tier
        } else {
            currentTier = .free
        }
    }

    /// Set the current subscription tier
    func setTier(_ tier: PricingTier) {
        currentTier = tier
        UserDefaults.standard.set(tier.rawValue, forKey: userDefaultsKey)
    }

    /// Maximum number of days of history available based on current tier
    var maxHistoryDays: Int {
        switch currentTier {
        case .free: return 7
        case .insights: return 30
        case .complete: return Int.max  // unlimited
        }
    }

    /// Whether AI insights are available
    var hasAIInsights: Bool {
        currentTier != .free
    }

    /// Whether weekly AI reports are available
    var hasWeeklyAIReports: Bool {
        currentTier != .free
    }

    /// Whether heart rate analysis is available
    var hasHeartRateAnalysis: Bool {
        currentTier != .free
    }

    /// Whether HRV analysis is available
    var hasHRVAnalysis: Bool {
        currentTier == .complete
    }

    /// Whether family sharing is available
    var hasFamilySharing: Bool {
        currentTier == .complete
    }

    /// Whether consultation recommendations are available
    var hasConsultationRecommendations: Bool {
        currentTier == .complete
    }

    /// Whether advanced patterns (seasonal, etc.) are available
    var hasAdvancedPatterns: Bool {
        currentTier == .complete
    }

    /// Whether Oura integration is available
    var hasOuraIntegration: Bool {
        currentTier == .insights || currentTier == .complete
    }

    /// Whether Withings integration is available
    var hasWithingsIntegration: Bool {
        currentTier == .insights || currentTier == .complete
    }

    /// Check if a specific feature is accessible
    func canAccess(_ feature: Feature) -> Bool {
        switch feature {
        case .basicSleepHistory:
            return true  // always available
        case .aiInsights:
            return hasAIInsights
        case .heartRateAnalysis:
            return hasHeartRateAnalysis
        case .hrvAnalysis:
            return hasHRVAnalysis
        case .weeklyReports:
            return hasWeeklyAIReports
        case .familySharing:
            return hasFamilySharing
        case .consultationRecommendations:
            return hasConsultationRecommendations
        case .advancedPatterns:
            return hasAdvancedPatterns
        case .ouraIntegration:
            return hasOuraIntegration
        case .withingsIntegration:
            return hasWithingsIntegration
        case .healthExport:
            return currentTier != .free
        }
    }

    /// Filter records to only include those within the history limit
    func filterRecordsToLimit(_ records: [SleepRecord]) -> [SleepRecord] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxHistoryDays, to: Date()) ?? Date()

        return records.filter { $0.date >= cutoffDate }
    }

    /// Upgrade prompt message if feature is not available
    func upgradePrompt(for feature: Feature) -> String? {
        guard !canAccess(feature) else { return nil }

        switch feature {
        case .aiInsights, .weeklyReports:
            return "Upgrade to Insights or Complete to access AI-powered sleep insights."
        case .heartRateAnalysis:
            return "Upgrade to Insights or Complete for heart rate analysis."
        case .hrvAnalysis, .familySharing, .consultationRecommendations, .advancedPatterns:
            return "Upgrade to Complete for this feature."
        case .ouraIntegration, .withingsIntegration:
            return "Upgrade to Insights or Complete to connect your devices."
        case .healthExport:
            return "Upgrade to access health data export."
        case .basicSleepHistory:
            return nil
        }
    }

    enum Feature {
        case basicSleepHistory
        case aiInsights
        case heartRateAnalysis
        case hrvAnalysis
        case weeklyReports
        case familySharing
        case consultationRecommendations
        case advancedPatterns
        case ouraIntegration
        case withingsIntegration
        case healthExport
    }
}
