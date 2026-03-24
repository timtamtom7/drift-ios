import Foundation
import SQLite

@MainActor
class DatabaseService: ObservableObject {
    private var db: Connection?

    private let sleepRecords = Table("sleep_records")
    private let colId = SQLite.Expression<String>("id")
    private let colDate = SQLite.Expression<Date>("date")
    private let colTotalDuration = SQLite.Expression<Double>("total_duration")
    private let colFellAsleepTime = SQLite.Expression<Date>("fell_asleep_time")
    private let colWokeUpTime = SQLite.Expression<Date>("woke_up_time")
    private let colStagesJSON = SQLite.Expression<String>("stages_json")
    private let colScore = SQLite.Expression<Int>("score")
    private let colHeartRateMin = SQLite.Expression<Int?>("heart_rate_min")
    private let colHeartRateMax = SQLite.Expression<Int?>("heart_rate_max")
    private let colHeartRateAvg = SQLite.Expression<Int?>("heart_rate_avg")
    private let colHrvAvg = SQLite.Expression<Double?>("hrv_avg")
    private let colRespiratoryRateAvg = SQLite.Expression<Double?>("respiratory_rate_avg")
    private let colSpo2Avg = SQLite.Expression<Double?>("spo2_avg")
    private let colSpo2DropsBelow90 = SQLite.Expression<Int?>("spo2_drops_below_90")
    private let colWristTempAvg = SQLite.Expression<Double?>("wrist_temp_avg")
    private let colCaffeineMg = SQLite.Expression<Double?>("caffeine_mg")
    private let colExerciseMinutes = SQLite.Expression<Double?>("exercise_minutes")
    private let colMindfulMinutes = SQLite.Expression<Double?>("mindful_minutes")
    private let colInsight = SQLite.Expression<String?>("insight")

    // Weekly Reports table
    private let weeklyReports = Table("weekly_reports")
    private let colReportId = SQLite.Expression<String>("id")
    private let colWeekStartDate = SQLite.Expression<Date>("week_start_date")
    private let colWeekEndDate = SQLite.Expression<Date>("week_end_date")
    private let colGeneratedAt = SQLite.Expression<Date>("generated_at")
    private let colAverageScore = SQLite.Expression<Int>("average_score")
    private let colAverageHours = SQLite.Expression<Double>("average_hours")
    private let colTotalNights = SQLite.Expression<Int>("total_nights")
    private let colAverageDeepMinutes = SQLite.Expression<Int>("average_deep_minutes")
    private let colAverageRemMinutes = SQLite.Expression<Int>("average_rem_minutes")
    private let colBestNightJSON = SQLite.Expression<String?>("best_night_json")
    private let colWorstNightJSON = SQLite.Expression<String?>("worst_night_json")
    private let colInsightsJSON = SQLite.Expression<String>("insights_json")
    private let colTrend = SQLite.Expression<String>("trend")
    private let colHrvAverage = SQLite.Expression<Double?>("hrv_average")
    private let colCorrelationsJSON = SQLite.Expression<String>("correlations_json")

    init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("drift.sqlite3")
            db = try Connection(path.path)
            try createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(sleepRecords.create(ifNotExists: true) { t in
            t.column(colId, primaryKey: true)
            t.column(colDate)
            t.column(colTotalDuration)
            t.column(colFellAsleepTime)
            t.column(colWokeUpTime)
            t.column(colStagesJSON)
            t.column(colScore)
            t.column(colHeartRateMin)
            t.column(colHeartRateMax)
            t.column(colHeartRateAvg)
            t.column(colHrvAvg)
            t.column(colRespiratoryRateAvg)
            t.column(colSpo2Avg)
            t.column(colSpo2DropsBelow90)
            t.column(colWristTempAvg)
            t.column(colCaffeineMg)
            t.column(colExerciseMinutes)
            t.column(colMindfulMinutes)
            t.column(colInsight)
        })

        try db?.run(weeklyReports.create(ifNotExists: true) { t in
            t.column(colReportId, primaryKey: true)
            t.column(colWeekStartDate)
            t.column(colWeekEndDate)
            t.column(colGeneratedAt)
            t.column(colAverageScore)
            t.column(colAverageHours)
            t.column(colTotalNights)
            t.column(colAverageDeepMinutes)
            t.column(colAverageRemMinutes)
            t.column(colBestNightJSON)
            t.column(colWorstNightJSON)
            t.column(colInsightsJSON)
            t.column(colTrend)
            t.column(colHrvAverage)
            t.column(colCorrelationsJSON)
        })

        // Migrate existing tables if needed
        try migrateTables()
    }

    private func migrateTables() throws {
        guard let db = db else { return }

        // Helper to check if a column exists in a table using raw SQL
        func columnExists(tableName: String, columnName: String) throws -> Bool {
            let stmt = try db.prepare("PRAGMA table_info(\(tableName))")
            for row in stmt {
                if let colName = row[1] as? String, colName == columnName {
                    return true
                }
            }
            return false
        }

        // Migrate sleep_records table
        if !(try columnExists(tableName: "sleep_records", columnName: "caffeine_mg")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN caffeine_mg REAL")
        }
        if !(try columnExists(tableName: "sleep_records", columnName: "exercise_minutes")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN exercise_minutes REAL")
        }
        if !(try columnExists(tableName: "sleep_records", columnName: "mindful_minutes")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN mindful_minutes REAL")
        }
        if !(try columnExists(tableName: "sleep_records", columnName: "respiratory_rate_avg")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN respiratory_rate_avg REAL")
        }
        if !(try columnExists(tableName: "sleep_records", columnName: "spo2_avg")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN spo2_avg REAL")
        }
        if !(try columnExists(tableName: "sleep_records", columnName: "spo2_drops_below_90")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN spo2_drops_below_90 INTEGER")
        }
        if !(try columnExists(tableName: "sleep_records", columnName: "wrist_temp_avg")) {
            try db.execute("ALTER TABLE sleep_records ADD COLUMN wrist_temp_avg REAL")
        }

        // Migrate weekly_reports table
        if !(try columnExists(tableName: "weekly_reports", columnName: "correlations_json")) {
            try db.execute("ALTER TABLE weekly_reports ADD COLUMN correlations_json TEXT NOT NULL DEFAULT '[]'")
        }
    }

    func saveSleepRecord(_ record: SleepRecord) throws {
        guard let db = db else { return }

        let encoder = JSONEncoder()
        let stagesData = try encoder.encode(record.stages)
        let stagesString = String(data: stagesData, encoding: .utf8) ?? "[]"

        let insert = sleepRecords.insert(or: .replace,
            colId <- record.id.uuidString,
            colDate <- record.date,
            colTotalDuration <- record.totalDuration,
            colFellAsleepTime <- record.fellAsleepTime,
            colWokeUpTime <- record.wokeUpTime,
            colStagesJSON <- stagesString,
            colScore <- record.score,
            colHeartRateMin <- record.heartRateMin,
            colHeartRateMax <- record.heartRateMax,
            colHeartRateAvg <- record.heartRateAvg,
            colHrvAvg <- record.hrvAvg,
            colRespiratoryRateAvg <- record.respiratoryRateAvg,
            colSpo2Avg <- record.spo2Avg,
            colSpo2DropsBelow90 <- record.spo2DropsBelow90,
            colWristTempAvg <- record.wristTempAvg,
            colCaffeineMg <- record.caffeineMg,
            colExerciseMinutes <- record.exerciseMinutes,
            colMindfulMinutes <- record.mindfulMinutes,
            colInsight <- record.insight
        )

        try db.run(insert)
    }

    func fetchAllRecords() throws -> [SleepRecord] {
        guard let db = db else { return [] }

        var records: [SleepRecord] = []
        let decoder = JSONDecoder()

        for row in try db.prepare(sleepRecords.order(colDate.desc)) {
            guard let recordId = UUID(uuidString: row[colId]) else { continue }

            let stagesData = row[colStagesJSON].data(using: .utf8) ?? Data()
            let stages = (try? decoder.decode([SleepStage].self, from: stagesData)) ?? []

            let record = SleepRecord(
                id: recordId,
                date: row[colDate],
                totalDuration: row[colTotalDuration],
                fellAsleepTime: row[colFellAsleepTime],
                wokeUpTime: row[colWokeUpTime],
                stages: stages,
                score: row[colScore],
                heartRateMin: row[colHeartRateMin],
                heartRateMax: row[colHeartRateMax],
                heartRateAvg: row[colHeartRateAvg],
                hrvAvg: row[colHrvAvg],
                respiratoryRateAvg: row[colRespiratoryRateAvg],
                spo2Avg: row[colSpo2Avg],
                spo2DropsBelow90: row[colSpo2DropsBelow90],
                wristTempAvg: row[colWristTempAvg],
                caffeineMg: row[colCaffeineMg],
                exerciseMinutes: row[colExerciseMinutes],
                mindfulMinutes: row[colMindfulMinutes],
                insight: row[colInsight]
            )
            records.append(record)
        }

        return records
    }

    func fetchRecords(forLastNDays n: Int) throws -> [SleepRecord] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -(n - 1), to: Date()) else {
            return []
        }

        let startOfDay = calendar.startOfDay(for: startDate)
        let allRecords = try fetchAllRecords()
        return allRecords.filter { $0.date >= startOfDay }
    }

    func deleteRecord(id recordId: UUID) throws {
        guard let db = db else { return }
        let record = sleepRecords.filter(colId == recordId.uuidString)
        try db.run(record.delete())
    }

    // MARK: - Weekly Reports

    func saveWeeklyReport(_ report: WeeklyReport) throws {
        guard let db = db else { return }

        let encoder = JSONEncoder()

        let bestNightString: String?
        if let best = report.bestNight {
            let data = try encoder.encode(best)
            bestNightString = String(data: data, encoding: .utf8)
        } else {
            bestNightString = nil
        }

        let worstNightString: String?
        if let worst = report.worstNight {
            let data = try encoder.encode(worst)
            worstNightString = String(data: data, encoding: .utf8)
        } else {
            worstNightString = nil
        }

        let insightsData = try encoder.encode(report.insights)
        let insightsString = String(data: insightsData, encoding: .utf8) ?? "[]"

        let correlationsData = try encoder.encode(report.correlations)
        let correlationsString = String(data: correlationsData, encoding: .utf8) ?? "[]"

        let insert = weeklyReports.insert(or: .replace,
            colReportId <- report.id.uuidString,
            colWeekStartDate <- report.weekStartDate,
            colWeekEndDate <- report.weekEndDate,
            colGeneratedAt <- report.generatedAt,
            colAverageScore <- report.averageScore,
            colAverageHours <- report.averageHours,
            colTotalNights <- report.totalNights,
            colAverageDeepMinutes <- report.averageDeepMinutes,
            colAverageRemMinutes <- report.averageRemMinutes,
            colBestNightJSON <- bestNightString,
            colWorstNightJSON <- worstNightString,
            colInsightsJSON <- insightsString,
            colTrend <- report.trend.rawValue,
            colHrvAverage <- report.hrvAverage,
            colCorrelationsJSON <- correlationsString
        )

        try db.run(insert)
    }

    func fetchWeeklyReports() throws -> [WeeklyReport] {
        guard let db = db else { return [] }

        let decoder = JSONDecoder()
        var reports: [WeeklyReport] = []

        for row in try db.prepare(weeklyReports.order(colWeekStartDate.desc)) {
            guard let reportId = UUID(uuidString: row[colReportId]) else { continue }

            var bestNight: WeeklyReport.NightSummary?
            if let bestString = row[colBestNightJSON],
               let bestData = bestString.data(using: .utf8) {
                bestNight = try? decoder.decode(WeeklyReport.NightSummary.self, from: bestData)
            }

            var worstNight: WeeklyReport.NightSummary?
            if let worstString = row[colWorstNightJSON],
               let worstData = worstString.data(using: .utf8) {
                worstNight = try? decoder.decode(WeeklyReport.NightSummary.self, from: worstData)
            }

            var insights: [String] = []
            if let insightsData = row[colInsightsJSON].data(using: .utf8) {
                insights = (try? decoder.decode([String].self, from: insightsData)) ?? []
            }

            var correlations: [WeeklyReport.CorrelationInsight] = []
            if let corrData = row[colCorrelationsJSON].data(using: .utf8) {
                correlations = (try? decoder.decode([WeeklyReport.CorrelationInsight].self, from: corrData)) ?? []
            }

            let trend = WeeklyReport.TrendDirection(rawValue: row[colTrend]) ?? .stable

            let report = WeeklyReport(
                id: reportId,
                weekStartDate: row[colWeekStartDate],
                weekEndDate: row[colWeekEndDate],
                generatedAt: row[colGeneratedAt],
                averageScore: row[colAverageScore],
                averageHours: row[colAverageHours],
                totalNights: row[colTotalNights],
                averageDeepMinutes: row[colAverageDeepMinutes],
                averageRemMinutes: row[colAverageRemMinutes],
                bestNight: bestNight,
                worstNight: worstNight,
                insights: insights,
                trend: trend,
                hrvAverage: row[colHrvAverage],
                correlations: correlations
            )
            reports.append(report)
        }

        return reports
    }

    func fetchWeeklyReport(for weekStartDate: Date) throws -> WeeklyReport? {
        let allReports = try fetchWeeklyReports()
        let calendar = Calendar.current
        return allReports.first { calendar.isDate($0.weekStartDate, inSameDayAs: weekStartDate) }
    }
}
