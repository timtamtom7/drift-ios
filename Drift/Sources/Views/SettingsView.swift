import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @Binding var showPricing: Bool
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                List {
                    Section {
                        healthKitStatusRow
                    } header: {
                        Text("HealthKit")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        Button {
                            showPricing = true
                        } label: {
                            HStack {
                                SettingsRow(
                                    icon: "crown.fill",
                                    iconColor: Theme.warningAccent,
                                    title: "Upgrade to Premium"
                                )
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        Toggle(isOn: $notificationsEnabled) {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: Theme.warningAccent,
                                title: "Morning Notifications"
                            )
                        }
                        .tint(Theme.deepSleep)

                        Toggle(isOn: $hapticFeedback) {
                            SettingsRow(
                                icon: "hand.tap.fill",
                                iconColor: Theme.insightAccent,
                                title: "Haptic Feedback"
                            )
                        }
                        .tint(Theme.deepSleep)
                    } header: {
                        Text("Subscription & Preferences")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        NavigationLink {
                            AboutView()
                        } label: {
                            SettingsRow(
                                icon: "info.circle.fill",
                                iconColor: Theme.lightSleep,
                                title: "About Drift"
                            )
                        }

                        Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                            SettingsRow(
                                icon: "lock.shield.fill",
                                iconColor: Theme.deepSleep,
                                title: "Privacy Policy"
                            )
                        }
                    } header: {
                        Text("Information")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        HStack {
                            Spacer()
                            Text("Drift v1.0.0")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var healthKitStatusRow: some View {
        HStack {
            Image(systemName: healthKitService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(healthKitService.isAuthorized ? Theme.insightAccent : Theme.heartRate)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit Access")
                    .foregroundColor(Theme.textPrimary)
                Text(healthKitService.isAuthorized ? "Authorized" : "Not Authorized")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            if !healthKitService.isAuthorized {
                Button("Enable") {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
                .font(.subheadline.bold())
                .foregroundColor(Theme.deepSleep)
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundGradient],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Drift")
                        .font(.largeTitle.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                Text("Understand your sleep.")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)
                    .italic()

                Spacer()

                VStack(spacing: 8) {
                    Text("Sleep data powered by Apple HealthKit")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("Your data never leaves your device.")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
