import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SleepDashboardView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.fill")
                }

            SleepHistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }

            SleepGoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .frame(width: 320, height: 400)
    }
}
