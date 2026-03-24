import Foundation

struct FamilyMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var relationship: Relationship
    var isConnected: Bool
    var joinedAt: Date
    var lastSyncAt: Date?
    var sleepScore: Int?
    var averageSleepHours: Double?

    enum Relationship: String, Codable, CaseIterable {
        case partner = "Partner"
        case child = "Child"
        case parent = "Parent"
        case sibling = "Sibling"
        case other = "Other"

        var icon: String {
            switch self {
            case .partner: return "heart.fill"
            case .child: return "figure.child"
            case .parent: return "figure.stand"
            case .sibling: return "person.2.fill"
            case .other: return "person.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        relationship: Relationship,
        isConnected: Bool = false,
        joinedAt: Date = Date(),
        lastSyncAt: Date? = nil,
        sleepScore: Int? = nil,
        averageSleepHours: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.isConnected = isConnected
        self.joinedAt = joinedAt
        self.lastSyncAt = lastSyncAt
        self.sleepScore = sleepScore
        self.averageSleepHours = averageSleepHours
    }
}

struct FamilySleepScore: Equatable {
    let aggregateScore: Int
    let memberCount: Int
    let averageHours: Double
    let bestPerformer: FamilyMember?
    let needsImprovement: [FamilyMember]
    let trend: Trend

    enum Trend: String {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }

        var color: String {
            switch self {
            case .improving: return "insightAccent"
            case .stable: return "textSecondary"
            case .declining: return "heartRate"
            }
        }
    }

    var scoreGrade: String {
        switch aggregateScore {
        case 80...100: return "Excellent"
        case 65..<80: return "Good"
        case 50..<65: return "Fair"
        default: return "Needs Work"
        }
    }
}

struct SleepComparison: Identifiable {
    let id = UUID()
    let memberName: String
    let date: Date
    let yourSleepHours: Double
    let theirSleepHours: Double
    let yourScore: Int
    let theirScore: Int
    let winner: Winner

    enum Winner {
        case you
        case them
        case tie
    }
}
