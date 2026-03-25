import SwiftUI

struct MacHomeView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MacSleepDashboard()
                .tabItem {
                    Label("Sleep", systemImage: "moon.fill")
                }
                .tag(0)

            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            WeeklyView()
                .tabItem {
                    Label("Weekly", systemImage: "calendar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(Color(hex: "7B68EE"))
        .task {
            await healthKitService.requestAuthorization()
            if healthKitService.isAuthorized {
                await healthKitService.fetchTodaySleep()
                await healthKitService.fetchWeeklySleep()
            }
        }
    }
}

struct MacSleepDashboard: View {
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let record = healthKitService.todaySleep {
                    SleepScoreRing(score: record.score)
                        .frame(height: 220)

                    HStack(spacing: 16) {
                        StatCardMac(title: "Total Sleep", value: record.totalHoursFormatted, icon: "clock.fill", color: Color(hex: "6B5B95"))
                        StatCardMac(title: "Deep Sleep", value: record.deepSleepFormatted, icon: "moon.stars.fill", color: Color(hex: "9B7EBD"))
                        StatCardMac(title: "REM Sleep", value: record.remSleepFormatted, icon: "brain.head.profile", color: Color(hex: "7B68EE"))
                    }
                } else {
                    ContentUnavailableView(
                        "No Sleep Data",
                        systemImage: "moon.zzz",
                        description: Text("Wear your Apple Watch to bed to track sleep.")
                    )
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct StatCardMac: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
