import Foundation

/// Represents a user's sleep schedule — bedtime, wake time, and consistency patterns.
struct SleepSchedule: Codable, Equatable {
    let id: UUID
    var targetBedtime: Date?
    var targetWakeTime: Date?
    var isActive: Bool
    var windDownMinutesBefore: Int
    var weeklyConsistencyScore: Int // 0-100
    var weekdayAverageBedtime: Date?
    var weekdayAverageWakeTime: Date?
    var weekendAverageBedtime: Date?
    var weekendAverageWakeTime: Date?
    var socialJetlagMinutes: Int // offset between weekday and weekend schedules
    var chronotype: Chronotype
    var adherenceHistory: [ScheduleAdherenceEntry]
    var lastUpdated: Date

    /// How much the user's schedule deviates from their target (in minutes)
    var averageBedtimeDeviation: Int {
        guard let target = targetBedtime, let avg = weekdayAverageBedtime else { return 0 }
        return abs(minutesBetween(target, avg))
    }

    /// Whether user is a morning person, night owl, or intermediate
    enum Chronotype: String, Codable {
        case morningPerson = "Morning Person"
        case intermediate = "Intermediate"
        case nightOwl = "Night Owl"
        case unknown = "Unknown"

        var emoji: String {
            switch self {
            case .morningPerson: return "🌅"
            case .intermediate: return "⚖️"
            case .nightOwl: return "🦉"
            case .unknown: return "❓"
            }
        }

        var description: String {
            switch self {
            case .morningPerson: return "You naturally prefer an early sleep schedule."
            case .intermediate: return "You have a balanced, flexible sleep pattern."
            case .nightOwl: return "You naturally prefer a later sleep schedule."
            case .unknown: return "Not enough data yet."
            }
        }
    }

    /// Social jetlag severity
    enum SocialJetlagSeverity: String {
        case none = "None"
        case mild = "Mild"      // < 30 min offset
        case moderate = "Moderate" // 30-60 min offset
        case significant = "Significant" // 60-90 min offset
        case severe = "Severe"  // > 90 min offset

        var color: String {
            switch self {
            case .none: return "insightAccent"
            case .mild: return "insightAccent"
            case .moderate: return "warningAccent"
            case .significant: return "heartRate"
            case .severe: return "heartRate"
            }
        }

        var recommendation: String {
            switch self {
            case .none: return "Your weekday and weekend schedules are well aligned."
            case .mild: return "Minor shift between weekdays and weekends — keep it consistent."
            case .moderate: return "Try shifting your weekend schedule closer to weekdays."
            case .significant: return "Social jetlag may affect your sleep quality. Aim for ≤ 1hr difference."
            case .severe: return "Large schedule shifts are disrupting your body clock. Try a more consistent routine."
            }
        }
    }

    var socialJetlagSeverity: SocialJetlagSeverity {
        switch socialJetlagMinutes {
        case 0..<30: return .none
        case 30..<60: return .mild
        case 60..<90: return .moderate
        case 90..<120: return .significant
        default: return .severe
        }
    }

    init(id: UUID = UUID()) {
        self.id = id
        self.targetBedtime = nil
        self.targetWakeTime = nil
        self.isActive = false
        self.windDownMinutesBefore = 30
        self.weeklyConsistencyScore = 0
        self.weekdayAverageBedtime = nil
        self.weekdayAverageWakeTime = nil
        self.weekendAverageBedtime = nil
        self.weekendAverageWakeTime = nil
        self.socialJetlagMinutes = 0
        self.chronotype = .unknown
        self.adherenceHistory = []
        self.lastUpdated = Date()
    }

    private func minutesBetween(_ a: Date, _ b: Date) -> Int {
        let calendar = Calendar.current
        let diff = calendar.dateComponents([.minute], from: a, to: b)
        return diff.minute ?? 0
    }
}

/// Tracks adherence to scheduled sleep times day by day
struct ScheduleAdherenceEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let scheduledBedtime: Date?
    let actualBedtime: Date?
    let scheduledWakeTime: Date?
    let actualWakeTime: Date?
    let wasOnTime: Bool
    let deviationMinutes: Int

    init(
        id: UUID = UUID(),
        date: Date,
        scheduledBedtime: Date?,
        actualBedtime: Date?,
        scheduledWakeTime: Date?,
        actualWakeTime: Date?,
        wasOnTime: Bool,
        deviationMinutes: Int
    ) {
        self.id = id
        self.date = date
        self.scheduledBedtime = scheduledBedtime
        self.actualBedtime = actualBedtime
        self.scheduledWakeTime = scheduledWakeTime
        self.actualWakeTime = actualWakeTime
        self.wasOnTime = wasOnTime
        self.deviationMinutes = deviationMinutes
    }
}

/// Recommended bedtime for tonight
struct BedtimeRecommendation: Identifiable {
    let id = UUID()
    let recommendedBedtime: Date
    let windDownTime: Date
    let reason: String
    let consistencyBonus: Int // extra score for going to bed on schedule
    let daysUntilTargetMet: Int?

    var timeUntilWindDown: String {
        let diff = windDownTime.timeIntervalSinceNow
        if diff <= 0 { return "Now" }
        let hours = Int(diff / 3600)
        let minutes = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
