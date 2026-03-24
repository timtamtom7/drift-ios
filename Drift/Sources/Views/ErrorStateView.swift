import SwiftUI

// MARK: - Error State View (generic container)
struct ErrorStateView: View {
    let type: ErrorStateType
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            iconView
                .font(.system(size: 72))
                .foregroundStyle(iconGradient)
                .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text(type.title)
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)

                Text(type.message)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let action = type.primaryAction, let retry = retryAction {
                Button {
                    retry()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: action.icon)
                        Text(action.label)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch type {
        case .healthKitNotAuthorized:
            Image(systemName: "lock.shield.fill")
        case .noAppleWatchData:
            Image(systemName: "applewatch.slash.fill")
        case .watchNotPaired:
            Image(systemName: "iphone.and.arrow.forward")
        case .noSleepDataYet:
            Image(systemName: "moon.stars")
        }
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.deepSleep.opacity(0.8), Theme.remSleep.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Error State Type
enum ErrorStateType: Equatable {
    case healthKitNotAuthorized
    case noAppleWatchData
    case watchNotPaired
    case noSleepDataYet

    var title: String {
        switch self {
        case .healthKitNotAuthorized:
            return "Health Access Required"
        case .noAppleWatchData:
            return "No Sleep Records"
        case .watchNotPaired:
            return "Apple Watch Required"
        case .noSleepDataYet:
            return "No Sleep Data Yet"
        }
    }

    var message: String {
        switch self {
        case .healthKitNotAuthorized:
            return "Drift needs access to your sleep data from Apple Health to show your nightly insights."
        case .noAppleWatchData:
            return "Your Apple Watch didn't record sleep last night. Make sure it's charged and Sleep Lock is enabled."
        case .watchNotPaired:
            return "Drift uses your Apple Watch to track sleep. Pair one in the Apple Watch app to get started."
        case .noSleepDataYet:
            return "Wear your Apple Watch to bed and sync in the morning. Your sleep data will appear here."
        }
    }

    var primaryAction: (icon: String, label: String)? {
        switch self {
        case .healthKitNotAuthorized:
            return ("heart.fill", "Allow Health Access")
        case .noAppleWatchData:
            return ("arrow.clockwise", "Try Again")
        case .watchNotPaired:
            return ("applewatch", "Learn More")
        case .noSleepDataYet:
            return ("arrow.clockwise", "Refresh")
        }
    }
}
