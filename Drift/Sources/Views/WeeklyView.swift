import SwiftUI

struct WeeklyView: View {
    @EnvironmentObject var healthKitService: HealthKitService
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

                ScrollView {
                    VStack(spacing: 16) {
                        if healthKitService.weeklySleep.isEmpty {
                            emptyView
                        } else {
                            weekOverview
                            weeklyCards
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRecord) { record in
                RecordDetailSheet(record: record)
            }
        }
        .task {
            await insightService.setHistoricalRecords(healthKitService.weeklySleep)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("No weekly data yet")
                .font(.headline)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, 100)
    }

    private var weekOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Summary")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                WeeklyStatBox(
                    title: "Avg Score",
                    value: "\(averageScore)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Theme.scoreColor(for: averageScore)
                )

                WeeklyStatBox(
                    title: "Avg Hours",
                    value: String(format: "%.1f", averageHours),
                    icon: "clock.fill",
                    color: Theme.lightSleep
                )

                WeeklyStatBox(
                    title: "Nights",
                    value: "\(healthKitService.weeklySleep.count)",
                    icon: "moon.stars.fill",
                    color: Theme.deepSleep
                )
            }
        }
    }

    private var weeklyCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Nights")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(healthKitService.weeklySleep) { record in
                WeeklyCard(record: record) {
                    selectedRecord = record
                }
            }
        }
    }

    private var averageScore: Int {
        guard !healthKitService.weeklySleep.isEmpty else { return 0 }
        return healthKitService.weeklySleep.map { $0.score }.reduce(0, +) / healthKitService.weeklySleep.count
    }

    private var averageHours: Double {
        guard !healthKitService.weeklySleep.isEmpty else { return 0 }
        return healthKitService.weeklySleep.map { $0.totalDuration / 3600 }.reduce(0, +) / Double(healthKitService.weeklySleep.count)
    }
}

struct WeeklyStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(Theme.textPrimary)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }
}

struct WeeklyCard: View {
    let record: SleepRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayOfWeek)
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(record.totalHoursFormatted)
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundColor(Theme.textPrimary)
                        Text("Total")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }

                    MiniScoreRing(score: record.score, size: 44)
                }
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: record.date)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: record.date)
    }
}

struct MiniScoreRing: View {
    let score: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surface, lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    Theme.scoreColor(for: score),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

struct RecordDetailSheet: View {
    let record: SleepRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SleepScoreRing(score: record.score)
                            .frame(height: 180)

                        HStack(spacing: 12) {
                            StatCard(title: "Total", value: record.totalHoursFormatted, icon: "clock.fill", color: Theme.lightSleep)
                            StatCard(title: "Fell Asleep", value: formatTime(record.fellAsleepTime), icon: "bed.double.fill", color: Theme.deepSleep)
                        }
                        .padding(.horizontal)

                        SleepStagesBar(stages: record.stages)
                            .padding(.horizontal)
                            .glassCard()
                            .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.deepSleep)
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: record.date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
