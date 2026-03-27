import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @Binding var showPricing: Bool
    @State private var showOnboarding = false
    @State private var showError = false
    @State private var errorType: ErrorStateType = .healthKitNotAuthorized

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundGradient],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if !healthKitService.isAuthorized {
                        errorBanner
                    }

                    if let record = healthKitService.todaySleep {
                        tonightSleepSection(record)
                    } else {
                        emptyTonightSection
                    }

                    if !healthKitService.weeklySleep.isEmpty {
                        weeklyOverview
                        if let todayRecord = healthKitService.todaySleep {
                            HRVCard(record: todayRecord)
                            if todayRecord.hasRespiratoryData {
                                RespiratoryCard(record: todayRecord)
                            }
                        }
                        QuickStatsRow(records: healthKitService.weeklySleep)
                    }
                }
                .padding()
            }
        }
        .task {
            await healthKitService.fetchTodaySleep()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }

    private var errorBanner: some View {
        Button {
            Theme.haptic(.light)
            Task {
                await healthKitService.requestAuthorization()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(Theme.warningAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Access Required")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Tap to enable sleep tracking")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .background(Theme.warningAccent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("HealthKit access required. Tap to enable sleep tracking.")
    }

    private func tonightSleepSection(_ record: SleepRecord) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.title2.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                NavigationLink {
                    SleepScoreDetailView(record: record)
                } label: {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(Theme.insightAccent)
                }
                .accessibilityLabel("View sleep score details")
            }

            SleepScoreRing(score: record.score)
                .frame(height: 200)

            HStack(spacing: 24) {
                TimeCard(
                    icon: "bed.double.fill",
                    label: "Bedtime",
                    time: formatTime(record.fellAsleepTime),
                    color: Theme.deepSleep
                )

                TimeCard(
                    icon: "sunrise.fill",
                    label: "Wake Time",
                    time: formatTime(record.wokeUpTime),
                    color: Theme.warningAccent
                )

                TimeCard(
                    icon: "clock.fill",
                    label: "Duration",
                    time: record.totalHoursFormatted,
                    color: Theme.lightSleep
                )
            }

            SleepStagesBar(stages: record.stages)

            if record.heartRateAvg != nil || record.hrvAvg != nil {
                VitalsRow(record: record)
            }

            // AI insight navigation
            NavigationLink {
                SleepScoreDetailView(record: record)
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("View detailed analysis")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()
                .background(Theme.insightAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
            }
            .accessibilityLabel("View detailed sleep analysis")
        }
    }

    private var emptyTonightSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.title2.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }

            VStack(spacing: 16) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep.opacity(0.6), Theme.remSleep.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("No Sleep Data Yet")
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text("Wear your Apple Watch to bed to track your sleep.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Theme.haptic(.light)
                    Task {
                        await healthKitService.fetchTodaySleep()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                }
                .accessibilityLabel("Refresh sleep data")
            }
            .padding(.vertical, 40)
        }
    }

    private var weeklyOverview: some View {
        NavigationLink {
            WeeklyView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text("\(healthKitService.weeklySleep.count) nights tracked")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                WeeklyMiniChart(records: healthKitService.weeklySleep)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .background(Theme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View this week's sleep summary")
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct TimeCard: View {
    let icon: String
    let label: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(time)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
    }
}

struct VitalsRow: View {
    let record: SleepRecord

    var body: some View {
        HStack(spacing: 12) {
            if let hrAvg = record.heartRateAvg {
                VitalBox(
                    icon: "heart.fill",
                    value: "\(hrAvg)",
                    unit: "bpm",
                    label: "Avg HR",
                    color: Theme.heartRate
                )
            }

            if let hrv = record.hrvAvg {
                VitalBox(
                    icon: "waveform.path.ecg",
                    value: String(format: "%.0f", hrv),
                    unit: "ms",
                    label: "HRV",
                    color: Theme.insightAccent
                )
            }

            if let spo2 = record.spo2Avg {
                VitalBox(
                    icon: "lungs.fill",
                    value: String(format: "%.0f", spo2),
                    unit: "%",
                    label: "SpO₂",
                    color: Theme.lightSleep
                )
            }

            if record.hasRespiratoryData, let resp = record.respiratoryRateAvg {
                VitalBox(
                    icon: "wind",
                    value: String(format: "%.1f", resp),
                    unit: "brpm",
                    label: "Resp",
                    color: Theme.deepSleep
                )
            }
        }
    }
}

struct VitalBox: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
    }
}

struct QuickStatsRow: View {
    let records: [SleepRecord]

    var body: some View {
        HStack(spacing: 12) {
            QuickStatBox(
                title: "Avg Score",
                value: "\(averageScore)",
                icon: "chart.line.uptrend.xyaxis",
                color: Theme.scoreColor(for: averageScore)
            )

            QuickStatBox(
                title: "Avg Hours",
                value: String(format: "%.1f", averageHours),
                icon: "clock.fill",
                color: Theme.lightSleep
            )

            QuickStatBox(
                title: "Avg Deep",
                value: "\(averageDeepMinutes)m",
                icon: "moon.fill",
                color: Theme.deepSleep
            )
        }
    }

    private var averageScore: Int {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.score }.reduce(0, +) / records.count
    }

    private var averageHours: Double {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.totalDuration / 3600 }.reduce(0, +) / Double(records.count)
    }

    private var averageDeepMinutes: Int {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.deepSleepMinutes }.reduce(0, +) / records.count
    }
}

struct QuickStatBox: View {
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
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(Theme.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
    }
}

struct WeeklyMiniChart: View {
    let records: [SleepRecord]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(records.suffix(7)) { record in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.scoreColor(for: record.score))
                    .frame(width: 8, height: CGFloat(record.score) / 100.0 * 24 + 8)
            }
        }
        .frame(height: 40)
    }
}
