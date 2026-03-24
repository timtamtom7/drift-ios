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
    let correlations: [CorrelationInsight]

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

    struct CorrelationInsight: Codable, Identifiable {
        let id: UUID
        let factor: String
        let description: String
        let strength: CorrelationStrength
        let emoji: String

        enum CorrelationStrength: String, Codable {
            case strong = "strong"
            case moderate = "moderate"
            case weak = "weak"

            var label: String {
                switch self {
                case .strong: return "Strong"
                case .moderate: return "Moderate"
                case .weak: return "Weak"
                }
            }
        }
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
