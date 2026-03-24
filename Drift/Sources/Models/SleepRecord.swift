import Foundation

struct SleepRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let totalDuration: TimeInterval
    let fellAsleepTime: Date
    let wokeUpTime: Date
    let stages: [SleepStage]
    let score: Int
    let heartRateMin: Int?
    let heartRateMax: Int?
    let heartRateAvg: Int?
    let hrvAvg: Double?
    let respiratoryRateAvg: Double?
    let spo2Avg: Double?
    let spo2DropsBelow90: Int?
    let wristTempAvg: Double?
    let caffeineMg: Double?
    let exerciseMinutes: Double?
    let mindfulMinutes: Double?
    let insight: String?

    var totalHours: Double {
        totalDuration / 3600.0
    }

    var totalHoursFormatted: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var deepSleepMinutes: Int {
        stages.filter { $0.type == .deep }.reduce(0) { $0 + $1.durationMinutes }
    }

    var remSleepMinutes: Int {
        stages.filter { $0.type == .rem }.reduce(0) { $0 + $1.durationMinutes }
    }

    var lightSleepMinutes: Int {
        stages.filter { $0.type == .light }.reduce(0) { $0 + $1.durationMinutes }
    }

    var awakeMinutes: Int {
        stages.filter { $0.type == .awake }.reduce(0) { $0 + $1.durationMinutes }
    }

    var hasRespiratoryData: Bool {
        respiratoryRateAvg != nil || spo2Avg != nil
    }

    init(
        id: UUID = UUID(),
        date: Date,
        totalDuration: TimeInterval,
        fellAsleepTime: Date,
        wokeUpTime: Date,
        stages: [SleepStage],
        score: Int,
        heartRateMin: Int? = nil,
        heartRateMax: Int? = nil,
        heartRateAvg: Int? = nil,
        hrvAvg: Double? = nil,
        respiratoryRateAvg: Double? = nil,
        spo2Avg: Double? = nil,
        spo2DropsBelow90: Int? = nil,
        wristTempAvg: Double? = nil,
        caffeineMg: Double? = nil,
        exerciseMinutes: Double? = nil,
        mindfulMinutes: Double? = nil,
        insight: String? = nil
    ) {
        self.id = id
        self.date = date
        self.totalDuration = totalDuration
        self.fellAsleepTime = fellAsleepTime
        self.wokeUpTime = wokeUpTime
        self.stages = stages
        self.score = score
        self.heartRateMin = heartRateMin
        self.heartRateMax = heartRateMax
        self.heartRateAvg = heartRateAvg
        self.hrvAvg = hrvAvg
        self.respiratoryRateAvg = respiratoryRateAvg
        self.spo2Avg = spo2Avg
        self.spo2DropsBelow90 = spo2DropsBelow90
        self.wristTempAvg = wristTempAvg
        self.caffeineMg = caffeineMg
        self.exerciseMinutes = exerciseMinutes
        self.mindfulMinutes = mindfulMinutes
        self.insight = insight
    }
}
