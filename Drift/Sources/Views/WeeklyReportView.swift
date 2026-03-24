import SwiftUI

struct WeeklyReportView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var reportService = WeeklyReportService()
    @State private var reports: [WeeklyReport] = []
    @State private var selectedReport: WeeklyReport?
    @State private var isLoading = false
    @State private var showShareSheet = false
    @State private var reportToShare: WeeklyReport?

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
            .sheet(isPresented: $showShareSheet) {
                if let report = reportToShare {
                    WeeklyReportShareView(report: report)
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

                Button {
                    reportToShare = report
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.deepSleep)
                        .padding(8)
                        .background(Theme.deepSleep.opacity(0.15))
                        .clipShape(Circle())
                }
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

            // Correlations
            if !report.correlations.isEmpty {
                Divider()
                    .background(Theme.surface)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What Affects Your Sleep")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    ForEach(report.correlations) { correlation in
                        CorrelationRow(correlation: correlation)
                    }
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

// MARK: - Correlation Row

struct CorrelationRow: View {
    let correlation: WeeklyReport.CorrelationInsight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(correlation.emoji)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(correlation.factor)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    strengthBadge
                }

                Text(correlation.description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(10)
        .background(strengthColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var strengthBadge: some View {
        Text(correlation.strength.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(strengthColor)
            .clipShape(Capsule())
    }

    private var strengthColor: Color {
        switch correlation.strength {
        case .strong: return Theme.heartRate
        case .moderate: return Theme.warningAccent
        case .weak: return Theme.insightAccent
        }
    }
}

// MARK: - Weekly Report Share Card

struct WeeklyReportShareView: View {
    let report: WeeklyReport
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    WeeklyReportShareCard(report: report)
                        .padding(.horizontal)

                    if let image = renderedImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("Weekly Sleep Report", image: Image(uiImage: image))
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Report")
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
                        .padding(.horizontal)
                    }

                    Text("Tap the share button above to save or send your weekly sleep report")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Share Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
    }
}

struct WeeklyReportShareCard: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Drift")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Weekly Sleep Report")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(report.formattedDateRange)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                trendBadgeView
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Score
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(report.averageScore)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.scoreColor(for: report.averageScore))

                    Text("Sleep Score")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.lightSleep)
                        Text(String(format: "%.1fh avg", report.averageHours))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.deepSleep)
                        Text("\(report.totalNights) nights tracked")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }

                    if let hrv = report.hrvAverage {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.insightAccent)
                            Text(String(format: "%.0f ms HRV", hrv))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            // Stages
            HStack(spacing: 8) {
                StageBadge(label: "Deep", value: "\(report.averageDeepMinutes)m", color: Theme.deepSleep)
                StageBadge(label: "REM", value: "\(report.averageRemMinutes)m", color: Theme.remSleep)
                Spacer()
            }

            // Insights preview
            if !report.insights.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 \(report.insights.first ?? "")")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                        .lineLimit(2)

                    if report.insights.count > 1 {
                        Text("+\(report.insights.count - 1) more insights in the app")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "0d1020"), Color(hex: "141628")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ShareCardSizePreferenceKey.self,
                    value: geo.size
                )
            }
        )
        .onPreferenceChange(ShareCardSizePreferenceKey.self) { size in
            // Card rendered
        }
    }

    private var trendBadgeView: some View {
        VStack(spacing: 2) {
            Text(report.trend.emoji)
                .font(.system(size: 16, weight: .bold))
            Text(report.trend.description)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .foregroundColor(report.trend == .up ? Theme.insightAccent : (report.trend == .down ? Theme.heartRate : Theme.warningAccent))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            (report.trend == .up ? Theme.insightAccent : (report.trend == .down ? Theme.heartRate : Theme.warningAccent)).opacity(0.15)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StageBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct ShareCardSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
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
