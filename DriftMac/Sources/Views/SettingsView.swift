import SwiftUI

struct SettingsView: View {
    @AppStorage("bedtimeReminder") private var bedtimeReminder = true
    @AppStorage("wakeUpAlarm") private var wakeUpAlarm = false
    @State private var watchSyncStatus: WatchSyncStatus = .connected

    enum WatchSyncStatus {
        case connected
        case disconnected
        case syncing

        var title: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .syncing: return "Syncing..."
            }
        }

        var color: Color {
            switch self {
            case .connected: return Theme.insightAccent
            case .disconnected: return Theme.heartRate
            case .syncing: return Theme.warningAccent
            }
        }

        var icon: String {
            switch self {
            case .connected: return "applewatch.watchface"
            case .disconnected: return "applewatch"
            case .syncing: return "arrow.triangle.2.circlepath"
            }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.deepPurple, Color(hex: "0F0D1A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Apple Watch Sync Status
                    watchSyncCard

                    // Toggles
                    togglesCard
                }
                .padding(16)
            }
        }
    }

    private var watchSyncCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: watchSyncStatus.icon)
                    .font(.title2)
                    .foregroundStyle(watchSyncStatus.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Watch")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(watchSyncStatus.color)
                            .frame(width: 8, height: 8)

                        Text(watchSyncStatus.title)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                Button {
                    // Refresh sync
                    watchSyncStatus = .syncing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        watchSyncStatus = .connected
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            if watchSyncStatus == .connected {
                HStack(spacing: 16) {
                    syncStatItem(value: "6h 32m", label: "Last Sync")
                    syncStatItem(value: "4", label: "Days Tracked")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func syncStatItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var togglesCard: some View {
        VStack(spacing: 0) {
            // Bedtime Reminder
            Toggle(isOn: $bedtimeReminder) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Theme.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bedtime Reminder")
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)

                        Text("Get notified when it's time to sleep")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(16)

            Divider()
                .background(Theme.surfaceLight)

            // Wake-up Alarm
            Toggle(isOn: $wakeUpAlarm) {
                HStack(spacing: 12) {
                    Image(systemName: "alarm.fill")
                        .foregroundStyle(Theme.warningAccent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wake-up Alarm")
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)

                        Text("Smart alarm based on sleep cycle")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}
