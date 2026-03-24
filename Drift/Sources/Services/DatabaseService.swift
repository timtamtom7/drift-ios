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
        })
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
            colHrvAverage <- report.hrvAverage
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
                hrvAverage: row[colHrvAverage]
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
