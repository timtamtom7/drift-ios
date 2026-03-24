import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTab = 0
    @State private var hasRequestedAuth = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingCompleted")
    @State private var showPricing = false

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(isCompleted: $showOnboarding)
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundGradient],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView(showPricing: $showPricing)
                    .tabItem {
                        Label("Today", systemImage: "moon.fill")
                    }
                    .tag(0)

                WeeklyView()
                    .tabItem {
                        Label("Week", systemImage: "calendar")
                    }
                    .tag(1)

                TrendsView()
                    .tabItem {
                        Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(2)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                    .tag(3)

                SettingsView(showPricing: $showPricing)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(Theme.lightSleep)
        }
        .task {
            if !hasRequestedAuth {
                hasRequestedAuth = true
                await healthKitService.requestAuthorization()
                if healthKitService.isAuthorized {
                    await healthKitService.fetchTodaySleep()
                    await healthKitService.fetchWeeklySleep()
                }
            }
        }
        .sheet(isPresented: $showPricing) {
            PricingView(isPresented: $showPricing)
        }
    }
}
