import Foundation

enum SleepPhase: String, CaseIterable {
    case awake = "Awake"
    case light = "Light"
    case deep = "Deep"
    case rem = "REM"

    var icon: String {
        switch self {
        case .awake: return "sun.max.fill"
        case .light: return "cloud.moon.fill"
        case .deep: return "moon.stars.fill"
        case .rem: return "brain.head.profile"
        }
    }

    var description: String {
        switch self {
        case .awake: return "You're awake"
        case .light: return "Light sleep"
        case .deep: return "Deep sleep"
        case .rem: return "REM sleep"
        }
    }
}
