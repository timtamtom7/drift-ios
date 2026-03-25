import Foundation
import SwiftUI

enum SleepStageType: String, Codable, CaseIterable, Hashable {
    case deep = "Deep"
    case rem = "REM"
    case light = "Light"
    case awake = "Awake"

    var color: Color {
        switch self {
        case .deep: return Theme.deepSleep
        case .rem: return Theme.remSleep
        case .light: return Theme.lightSleep
        case .awake: return Theme.awake
        }
    }

    var shortLabel: String {
        switch self {
        case .deep: return "D"
        case .rem: return "R"
        case .light: return "L"
        case .awake: return "A"
        }
    }

    /// What happens in this sleep stage — real neuroscience
    var explanation: String {
        switch self {
        case .deep:
            return "Deep sleep is when your body repairs tissue, builds bone and muscle, and strengthens your immune system. It's hardest to wake from and leaves you feeling restored."
        case .rem:
            return "REM (Rapid Eye Movement) is when you dream and your brain consolidates memories and learning from the day. It's essential for emotional health and creativity."
        case .light:
            return "Light sleep acts as a transition phase between deeper stages. Your body slows down but remains alert enough to wake easily. It makes up the largest portion of your night."
        case .awake:
            return "Brief awakenings are completely normal — you may not even remember them. Frequent or prolonged awake periods, however, can fragment your sleep and reduce its restorative quality."
        }
    }
}

struct SleepStage: Identifiable, Codable, Hashable {
    let id: UUID
    let type: SleepStageType
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    init(id: UUID = UUID(), type: SleepStageType, startDate: Date, endDate: Date) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
    }
}
