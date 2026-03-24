import SwiftUI

struct WeeklyReportView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var reportService = WeeklyReportService()
    @State private var reports: [WeeklyReport] = []
    @State private var selectedReport: WeeklyReport?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Theme.deepSleep)
                } else if reports.isEmpty {
                    emptyReportView
                } else {
                    reportsList
                }
            }
            .navigationTitle("Weekly Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await generateNewReport() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Theme.deepSleep)
                    }
                    .disabled(reportService.isGenerating)
                }
            }
        }
        .task {
            await loadReports()
        }
    }

    private var emptyReportView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.textSecondary.opacity(0.5))

            VStack(spacing: 12) {
                Text("No Reports Yet")
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)

                Text("Weekly reports are generated every Sunday automatically. You can also generate one manually once you have at least 3 nights of sleep data.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                Task { await generateNewReport() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Report")
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
            .disabled(healthKitService.weeklySleep.count < 3)

            Spacer()
        }
    }

    private var reportsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let latestReport = reports.first {
                    latestReportCard(latestReport)
                }

                ForEach(reports.dropFirst()) { report in
                    ReportCard(report: report)
                }
            }
            .padding()
        }
    }

    private func latestReportCard(_ report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Report")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(report.formattedDateRange)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                trendBadge(report.trend)
            }

            // Main score
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(report.averageScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.scoreColor(for: report.averageScore))

                    Text("Avg Score")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Divider()
                    .background(Theme.surface)
                    .frame(height: 60)

                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.lightSleep)
                        Text(String(format: "%.1fh avg", report.averageHours))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.deepSleep)
                        Text("\(report.totalNights) nights")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.insightAccent)
                        if let hrv = report.hrvAverage {
                            Text(String(format: "%.0f ms avg HRV", hrv))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        } else {
                            Text("No HRV data")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }

            Divider()
                .background(Theme.surface)

            // Best/Worst
            HStack(spacing: 12) {
                if let best = report.bestNight {
                    BestWorstSummary(
                        label: "Best",
                        score: best.score,
                        date: best.date,
                        hours: best.hours,
                        color: Theme.insightAccent,
                        icon: "star.fill"
                    )
                }

                if let worst = report.worstNight {
                    BestWorstSummary(
                        label: "Worst",
                        score: worst.score,
                        date: worst.date,
                        hours: worst.hours,
                        color: Theme.heartRate,
                        icon: "exclamationmark.triangle.fill"
                    )
                }
            }

            // Insights
            if !report.insights.isEmpty {
                Divider()
                    .background(Theme.surface)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Insights")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    ForEach(Array(report.insights.enumerated()), id: \.offset) { _, insight in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.deepSleep)
                            Text(insight)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                }
            }

            // Generated timestamp
            HStack {
                Spacer()
                Text("Generated \(formatTimestamp(report.generatedAt))")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
        }
        .padding()
        .glassCard()
    }

    private func loadReports() async {
        let dbReports = (try? DatabaseService().fetchWeeklyReports()) ?? []
        reports = dbReports.sorted { $0.weekStartDate > $1.weekStartDate }
    }

    private func generateNewReport() async {
        isLoading = true
        defer { isLoading = false }

        if let newReport = await reportService.generateWeeklyReport(from: healthKitService.weeklySleep) {
            if let index = reports.firstIndex(where: { calendar.isDate($0.weekStartDate, inSameDayAs: newReport.weekStartDate) }) {
                reports[index] = newReport
            } else {
                reports.insert(newReport, at: 0)
            }
            reports.sort { $0.weekStartDate > $1.weekStartDate }
        }
    }

    private var calendar: Calendar { Calendar.current }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func trendBadge(_ trend: WeeklyReport.TrendDirection) -> some View {
        HStack(spacing: 4) {
            Text(trend.emoji)
                .font(.system(size: 12, weight: .bold))
            Text(trend.description)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(trend == .up ? Theme.insightAccent : (trend == .down ? Theme.heartRate : Theme.warningAccent))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (trend == .up ? Theme.insightAccent : (trend == .down ? Theme.heartRate : Theme.warningAccent)).opacity(0.15)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ReportCard: View {
    let report: WeeklyReport
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.formattedDateRange)
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.textPrimary)

                        Text("\(report.totalNights) nights")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text("\(report.averageScore)")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(Theme.scoreColor(for: report.averageScore))

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Theme.surface)

                    HStack(spacing: 16) {
                        ReportStatItem(label: "Avg Hours", value: String(format: "%.1f", report.averageHours), color: Theme.lightSleep)
                        ReportStatItem(label: "Avg Deep", value: "\(report.averageDeepMinutes)m", color: Theme.deepSleep)
                        ReportStatItem(label: "Avg REM", value: "\(report.averageRemMinutes)m", color: Theme.remSleep)
                    }

                    if !report.insights.isEmpty {
                        Divider()
                            .background(Theme.surface)

                        ForEach(Array(report.insights.enumerated()), id: \.offset) { _, insight in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.deepSleep)
                                Text(insight)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                                    .lineSpacing(1)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .glassCard()
    }
}

struct BestWorstSummary: View {
    let label: String
    let score: Int
    let date: Date
    let hours: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }

            Text("\(score)")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(color)

            Text(formatDate(date))
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)

            Text(hours)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct ReportStatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
