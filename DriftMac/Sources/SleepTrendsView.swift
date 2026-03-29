import SwiftUI

/// Dashboard showing 30/60/90 day sleep trends with baseline comparison
struct SleepTrendsView: View {
    @State private var selectedPeriod: TrendPeriod = .thirtyDays
    @State private var trendData: TrendData?
    @State private var isLoading = false
    @State private var improvementPercentage: Double?

    private let healthKitService = HealthKitService.shared
    private let sleepReportService = SleepReportService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Period Selector
            periodSelector

            Divider()
                .padding(.vertical, 8)

            if isLoading {
                loadingView
            } else if let data = trendData {
                ScrollView {
                    VStack(spacing: 20) {
                        improvementBanner(data: data)
                        trendChart(data: data)
                        baselineComparison(data: data)
                        periodStats(data: data)
                    }
                    .padding()
                }
            } else {
                emptyState
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .task {
            await loadTrendData()
        }
        .onChange(of: selectedPeriod) { _, newValue in
            Task { await loadTrendData() }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TrendPeriod.allCases, id: \.self) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Improvement Banner

    @ViewBuilder
    private func improvementBanner(data: TrendData) -> some View {
        if let improvement = improvementPercentage {
            HStack {
                Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(improvement >= 0 ? .green : .orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your sleep has \(improvement >= 0 ? "improved" : "changed") \(String(format: "%.0f", abs(improvement)))% this \(selectedPeriod.label.lowercased())")
                        .font(.headline)
                    Text(selectedPeriod.improvementContext)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Theme.purple.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Trend Chart

    private func trendChart(data: TrendData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Score Trend")
                .font(.headline)

            SleepTrendChart(scoreHistory: data.scoreHistory)
                .frame(height: 180)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)

            HStack {
                ForEach(data.scoreHistory.suffix(5).indices, id: \.self) { index in
                    if index > 0 {
                        Spacer()
                    }
                    VStack(spacing: 4) {
                        Text("\(data.scoreHistory[data.scoreHistory.count - 5 + index])")
                            .font(.caption.bold())
                        Text(selectedPeriod.shortLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Baseline Comparison

    private func baselineComparison(data: TrendData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compared to Your Baseline")
                .font(.headline)

            HStack(spacing: 24) {
                baselineMetric(
                    title: "Average Score",
                    current: data.avgScore,
                    baseline: data.baselineScore,
                    unit: "/100"
                )

                baselineMetric(
                    title: "Avg Sleep",
                    current: data.avgSleep,
                    baseline: data.baselineSleep,
                    unit: ""
                )

                baselineMetric(
                    title: "Deep Sleep",
                    current: data.avgDeepSleep,
                    baseline: data.baselineDeepSleep,
                    unit: ""
                )
            }

            // Visual baseline bar
            GeometryReader { geometry in
                let currentWidth = min(1.0, CGFloat(data.avgScore) / 100.0) * geometry.size.width
                let baselineWidth = min(1.0, CGFloat(data.baselineScore) / 100.0) * geometry.size.width

                ZStack(alignment: .leading) {
                    // Baseline
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: baselineWidth, height: 24)
                        .overlay(
                            Text("Baseline: \(data.baselineScore)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4),
                            alignment: .leading
                        )

                    // Current
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.purple)
                        .frame(width: currentWidth, height: 24)
                        .overlay(
                            Text("Current: \(data.avgScore)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.leading, 4),
                            alignment: .leading
                        )
                }
            }
            .frame(height: 28)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private func baselineMetric(title: String, current: Double, baseline: Double, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", current))
                    .font(.title2.bold())
                if unit == "/100" {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            let diff = current - baseline
            if abs(diff) > 0.5 {
                HStack(spacing: 2) {
                    Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text(String(format: "%.1f", abs(diff)))
                        .font(.caption2)
                }
                .foregroundColor(diff > 0 ? .green : .orange)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Period Stats

    private func periodStats(data: TrendData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedPeriod.label) Summary")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(title: "Nights Tracked", value: "\(data.nightsTracked)", icon: "moon.stars")
                statCard(title: "Best Night", value: formatDuration(data.bestNight), icon: "star")
                statCard(title: "Worst Night", value: formatDuration(data.worstNight), icon: "exclamationmark.triangle")
                statCard(title: "Average Duration", value: formatDuration(data.avgSleep), icon: "clock")
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }

            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Loading & Empty

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Analyzing sleep trends...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Not enough sleep data yet")
                .font(.headline)
            Text("Track at least 7 nights to see trends")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadTrendData() async {
        isLoading = true

        let days = selectedPeriod.days
        let history = (try? await healthKitService.getSleepHistory(days: days)) ?? []

        let scoreHistory = history.map { $0.sleepScore }
        let avgScore = scoreHistory.isEmpty ? 0 : scoreHistory.reduce(0, +) / scoreHistory.count
        let avgSleep = history.isEmpty ? 0 : history.map(\.totalSleep).reduce(0, +) / Double(history.count)
        let avgDeep = history.isEmpty ? 0 : history.map(\.deepSleep).reduce(0, +) / Double(max(1, history.count))

        // Baseline = previous period's average
        let baselineDays = days * 2
        let baselineHistory = (try? await healthKitService.getSleepHistory(days: baselineDays)) ?? []
        let baselineScore = baselineHistory.isEmpty ? avgScore : baselineHistory.map(\.sleepScore).reduce(0, +) / baselineHistory.count
        let baselineSleep = baselineHistory.isEmpty ? avgSleep : baselineHistory.map(\.totalSleep).reduce(0, +) / Double(max(1, baselineHistory.count))
        let baselineDeep = baselineHistory.isEmpty ? avgDeep : baselineHistory.map(\.deepSleep).reduce(0, +) / Double(max(1, baselineHistory.count))

        // Calculate improvement
        if baselineScore > 0 {
            improvementPercentage = ((Double(avgScore) - Double(baselineScore)) / Double(baselineScore)) * 100
        }

        let bestNight = history.max(by: { $0.sleepScore < $1.sleepScore })?.totalSleep ?? 0
        let worstNight = history.min(by: { $0.sleepScore < $1.sleepScore })?.totalSleep ?? 0

        trendData = TrendData(
            scoreHistory: scoreHistory,
            avgScore: Double(avgScore),
            avgSleep: avgSleep,
            avgDeepSleep: avgDeep,
            baselineScore: Double(baselineScore),
            baselineSleep: baselineSleep,
            baselineDeepSleep: baselineDeep,
            nightsTracked: history.count,
            bestNight: bestNight,
            worstNight: worstNight
        )

        isLoading = false
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Supporting Types

enum TrendPeriod: CaseIterable {
    case thirtyDays
    case sixtyDays
    case ninetyDays

    var label: String {
        switch self {
        case .thirtyDays: return "30 Days"
        case .sixtyDays: return "60 Days"
        case .ninetyDays: return "90 Days"
        }
    }

    var shortLabel: String {
        switch self {
        case .thirtyDays: return "30D"
        case .sixtyDays: return "60D"
        case .ninetyDays: return "90D"
        }
    }

    var days: Int {
        switch self {
        case .thirtyDays: return 30
        case .sixtyDays: return 60
        case .ninetyDays: return 90
        }
    }

    var improvementContext: String {
        switch self {
        case .thirtyDays: return "vs. previous 30 days"
        case .sixtyDays: return "vs. previous 60 days"
        case .ninetyDays: return "vs. previous 90 days"
        }
    }
}

struct TrendData {
    let scoreHistory: [Int]
    let avgScore: Double
    let avgSleep: TimeInterval
    let avgDeepSleep: TimeInterval
    let baselineScore: Double
    let baselineSleep: TimeInterval
    let baselineDeepSleep: TimeInterval
    let nightsTracked: Int
    let bestNight: TimeInterval
    let worstNight: TimeInterval
}

// MARK: - Trend Chart

struct SleepTrendChart: View {
    let scoreHistory: [Int]

    var body: some View {
        GeometryReader { geometry in
            if scoreHistory.count >= 2 {
                let maxScore: CGFloat = 100
                let points = scoreHistory.enumerated().map { index, score in
                    CGPoint(
                        x: CGFloat(index) / CGFloat(max(scoreHistory.count - 1, 1)) * geometry.size.width,
                        y: geometry.size.height - (CGFloat(score) / maxScore * geometry.size.height)
                    )
                }

                ZStack {
                    // Grid lines
                    ForEach([25, 50, 75, 100], id: \.self) { line in
                        Path { path in
                            let y = geometry.size.height - (CGFloat(line) / maxScore * geometry.size.height)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    }

                    // Line chart
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                    // Area fill
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: CGPoint(x: first.x, y: geometry.size.height))
                        path.addLine(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Data points
                    ForEach(scoreHistory.indices, id: \.self) { index in
                        Circle()
                            .fill(Theme.purple)
                            .frame(width: 6, height: 6)
                            .position(points[index])
                    }
                }
            } else {
                Text("Not enough data points")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SleepTrendsView()
        .frame(width: 450, height: 600)
}
