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
        self.insight = insight
    }
}
