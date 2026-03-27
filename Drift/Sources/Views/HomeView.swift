import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @Binding var showPricing: Bool
    @State private var currentInsight: SleepInsight?
    @State private var showHRVDetail = false
    @State private var selectedRecord: SleepRecord?
    private let insightService = AIInsightService()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if !healthKitService.isAuthorized {
                    healthKitNotAuthorizedView
                } else if healthKitService.isLoading {
                    loadingView
                } else if let record = healthKitService.todaySleep {
                    sleepSummaryView(record: record)
                } else {
                    noSleepDataYetView
                }
            }
            .navigationTitle("Drift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                await healthKitService.fetchTodaySleep()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Theme.textSecondary)
                        }

                        Button {
                            showPricing = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Theme.warningAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showHRVDetail) {
                HRVTrendChartView(records: healthKitService.weeklySleep)
            }
            .navigationDestination(item: $selectedRecord) { record in
                SleepScoreDetailView(record: record)
            }
        }
    }

    private var healthKitNotAuthorizedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.deepSleep, Theme.remSleep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                if healthKitService.authorizationDenied {
                    Text("Health Access Denied")
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text("You denied HealthKit access. Enable it in Settings → Privacy → Health → Drift to see your sleep insights.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Text("Unlock Your Sleep Data")
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text("Drift needs access to your HealthKit sleep data to show your nightly insights.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            if !healthKitService.authorizationDenied {
                Button {
                    Task {
                        await healthKitService.requestAuthorization()
                        if healthKitService.isAuthorized {
                            await healthKitService.fetchTodaySleep()
                            await healthKitService.fetchWeeklySleep()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                        Text("Allow Health Access")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            } else {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: settingsURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Theme.deepSleep, Theme.remSleep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.deepSleep)
            Text("Loading sleep data...")
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var noSleepDataYetView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.stars")
                .font(.system(size: 72))
                .foregroundColor(Theme.textSecondary.opacity(0.5))

            VStack(spacing: 12) {
                Text("No Sleep Data Yet")
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)

                Text("Wear your Apple Watch to bed and sync in the morning. Your sleep data will appear here.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                Task {
                    await healthKitService.fetchTodaySleep()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
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

            Spacer()
        }
    }

    private func sleepSummaryView(record: SleepRecord) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                greetingHeader

                Button {
                    selectedRecord = record
                } label: {
                    SleepScoreRing(score: record.score)
                        .frame(height: 200)
                }
                .buttonStyle(.plain)

                statsRow(record: record)

                SleepStagesBar(stages: record.stages)
                    .frame(height: 120)
                    .padding(.horizontal)
                    .glassCard()

                if let insight = currentInsight {
                    InsightCard(insight: insight)
                        .padding(.horizontal)
                } else {
                    // Skeleton insight
                    InsightSkeletonCard()
                        .padding(.horizontal)
                }

                if record.heartRateMin != nil {
                    heartRateRow(record: record)
                        .padding(.horizontal)
                }

                Button {
                    showHRVDetail = true
                } label: {
                    HRVCard(record: record)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                if record.hasRespiratoryData {
                    RespiratoryCard(record: record)
                        .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .task {
            await insightService.setHistoricalRecords(healthKitService.weeklySleep)
            currentInsight = await insightService.generateInsight(for: record)
        }
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private func statsRow(record: SleepRecord) -> some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: record.totalHoursFormatted,
                icon: "clock.fill",
                color: Theme.lightSleep
            )

            StatCard(
                title: "Fell Asleep",
                value: formatTime(record.fellAsleepTime),
                icon: "bed.double.fill",
                color: Theme.deepSleep
            )
        }
        .padding(.horizontal)
    }

    private func heartRateRow(record: SleepRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 16) {
                HeartRateStat(value: "\(record.heartRateMin ?? 0)", label: "Min", color: Theme.insightAccent)
                HeartRateStat(value: "\(record.heartRateMax ?? 0)", label: "Max", color: Theme.heartRate)
                HeartRateStat(value: "\(record.heartRateAvg ?? 0)", label: "Avg", color: Theme.warningAccent)
            }
        }
        .padding()
        .glassCard()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning"
        } else if hour < 17 { return "Good afternoon"
        } else { return "Good evening" }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Insight Skeleton
struct InsightSkeletonCard: View {
    @State private var shimmer = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Theme.surface)
                .frame(width: 3, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("💡")
                        .font(.system(size: 14))
                    Text("Insight")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surface.opacity(shimmer ? 0.5 : 0.3))
                    .frame(height: 14)
                    .frame(maxWidth: 220)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.surface.opacity(shimmer ? 0.3 : 0.2))
                    .frame(height: 14)
                    .frame(maxWidth: 160)
            }

            Spacer()
        }
        .padding()
        .glassCard()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(1)
                Text(value)
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

struct HeartRateStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced).bold())
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension View {
    func glassCard() -> some View {
        self
            .background(Theme.surfaceGlass)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
