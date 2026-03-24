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
    private let colInsight = SQLite.Expression<String?>("insight")

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
            t.column(colInsight)
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
}
