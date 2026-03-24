import Foundation

struct WeeklyReport: Identifiable, Codable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    let generatedAt: Date
    let averageScore: Int
    let averageHours: Double
    let totalNights: Int
    let averageDeepMinutes: Int
    let averageRemMinutes: Int
    let bestNight: NightSummary?
    let worstNight: NightSummary?
    let insights: [String]
    let trend: TrendDirection
    let hrvAverage: Double?

    enum TrendDirection: String, Codable {
        case up = "up"
        case down = "down"
        case stable = "stable"

        var emoji: String {
            switch self {
            case .up: return "↑"
            case .down: return "↓"
            case .stable: return "→"
            }
        }

        var description: String {
            switch self {
            case .up: return "Improving"
            case .down: return "Declining"
            case .stable: return "Stable"
            }
        }
    }

    struct NightSummary: Codable {
        let date: Date
        let score: Int
        let hours: String
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) – \(formatter.string(from: weekEndDate))"
    }

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Week of' MMM d"
        return formatter.string(from: weekStartDate)
    }
}
