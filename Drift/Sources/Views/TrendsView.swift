import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var trendRecords: [SleepRecord] = []
    @State private var selectedTimeRange: TimeRange = .thirtyDays
    @State private var isLoading = false

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case twoWeeks = "14D"
        case thirtyDays = "30D"
    }

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
                } else if trendRecords.isEmpty {
                    emptyTrendsView
                } else {
                    trendsContent
                }
            }
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadTrends()
        }
    }

    private var emptyTrendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("Not enough data for trends")
                .font(.headline)
                .foregroundColor(Theme.textSecondary)
            Text("Wear your Apple Watch to bed for at least 3 nights to see your sleep trends.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var trendsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                timeRangePicker
                trendChart
                monthComparisonCard
                bestWorstCard
                trendStatsRow
                if !correlationInsights.isEmpty {
                    correlationSection
                }
                if hasRespiratoryData {
                    respiratoryTrendCard
                }
            }
            .padding()
        }
    }

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                    Task { await loadTrends() }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedTimeRange == range ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedTimeRange == range ? Theme.deepSleep : Color.clear
                        )
                }
            }
        }
        .glassCard()
        .padding(.horizontal)
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sleep Quality Trend")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.lightSleep)
                    .font(.caption)
            }

            Chart {
                ForEach(trendRecords) { record in
                    LineMark(
                        x: .value("Date", record.date, unit: .day),
                        y: .value("Score", record.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("Date", record.date, unit: .day),
                        y: .value("Score", record.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep.opacity(0.3), Theme.deepSleep.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                if let avgScore = averageScore {
                    RuleMark(y: .value("Average", avgScore))
                        .foregroundStyle(Theme.warningAccent.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Avg: \(avgScore)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.warningAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.surface.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: strideCount)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.surface)
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 20)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.surface)
                    AxisValueLabel()
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
        }
        .padding()
        .glassCard()
    }

    private var strideCount: Int {
        switch selectedTimeRange {
        case .week: return 1
        case .twoWeeks: return 2
        case .thirtyDays: return 5
        }
    }

    private var monthComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Month Comparison")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            let (thisMonth, lastMonth) = monthComparison

            HStack(spacing: 12) {
                MonthComparisonBox(
                    label: "This Month",
                    avgScore: thisMonth.avgScore,
                    avgHours: thisMonth.avgHours,
                    nights: thisMonth.nights,
                    isBetter: thisMonth.avgScore > lastMonth.avgScore,
                    hasData: thisMonth.nights > 0
                )

                MonthComparisonBox(
                    label: "Last Month",
                    avgScore: lastMonth.avgScore,
                    avgHours: lastMonth.avgHours,
                    nights: lastMonth.nights,
                    isBetter: false,
                    hasData: lastMonth.nights > 0
                )
            }

            if thisMonth.nights > 0 && lastMonth.nights > 0 {
                let diff = thisMonth.avgScore - lastMonth.avgScore
                HStack(spacing: 6) {
                    Image(systemName: diff >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(diff >= 0 ? Theme.insightAccent : Theme.heartRate)
                    Text(diff >= 0 ? "This month is \(abs(diff)) points better" : "This month is \(abs(diff)) points worse")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var monthComparison: (thisMonth: MonthStats, lastMonth: MonthStats) {
        let calendar = Calendar.current
        let now = Date()

        let thisMonthRecords = trendRecords.filter { record in
            calendar.isDate(record.date, equalTo: now, toGranularity: .month)
        }

        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let lastMonthRecords = trendRecords.filter { record in
            calendar.isDate(record.date, equalTo: lastMonthDate, toGranularity: .month)
        }

        return (
            MonthStats(from: thisMonthRecords),
            MonthStats(from: lastMonthRecords)
        )
    }

    private var bestWorstCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best & Worst Sleep")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            if let best = trendRecords.max(by: { $0.score < $1.score }),
               let worst = trendRecords.min(by: { $0.score < $1.score }) {
                HStack(spacing: 12) {
                    BestWorstBox(
                        label: "Best",
                        score: best.score,
                        date: best.date,
                        hours: best.totalHoursFormatted,
                        icon: "star.fill",
                        color: Theme.insightAccent
                    )

                    BestWorstBox(
                        label: "Worst",
                        score: worst.score,
                        date: worst.date,
                        hours: worst.totalHoursFormatted,
                        icon: "exclamationmark.triangle.fill",
                        color: Theme.heartRate
                    )
                }
            } else {
                Text("Not enough data")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .glassCard()
    }

    private var trendStatsRow: some View {
        HStack(spacing: 12) {
            TrendStatBox(
                title: "Avg Score",
                value: "\(averageScore ?? 0)",
                icon: "chart.bar.fill",
                color: Theme.scoreColor(for: averageScore ?? 0)
            )

            TrendStatBox(
                title: "Avg Hours",
                value: String(format: "%.1f", averageHours ?? 0),
                icon: "clock.fill",
                color: Theme.lightSleep
            )

            TrendStatBox(
                title: "Avg Deep",
                value: "\(averageDeepMinutes ?? 0)m",
                icon: "moon.fill",
                color: Theme.deepSleep
            )
        }
    }

    private var averageScore: Int? {
        guard !trendRecords.isEmpty else { return nil }
        return trendRecords.map { $0.score }.reduce(0, +) / trendRecords.count
    }

    private var averageHours: Double? {
        guard !trendRecords.isEmpty else { return nil }
        return trendRecords.map { $0.totalDuration / 3600 }.reduce(0, +) / Double(trendRecords.count)
    }

    private var averageDeepMinutes: Int? {
        guard !trendRecords.isEmpty else { return nil }
        return trendRecords.map { $0.deepSleepMinutes }.reduce(0, +) / trendRecords.count
    }

    private var hasRespiratoryData: Bool {
        trendRecords.contains { $0.hasRespiratoryData }
    }

    private var correlationInsights: [(factor: String, emoji: String, avgScoreWith: Int, avgScoreWithout: Int, countWith: Int)] {
        // Caffeine correlation
        var insights: [(factor: String, emoji: String, avgScoreWith: Int, avgScoreWithout: Int, countWith: Int)] = []

        let withCaffeine = trendRecords.filter { ($0.caffeineMg ?? 0) > 200 }
        let withoutCaffeine = trendRecords.filter { ($0.caffeineMg ?? 0) <= 200 }

        if withCaffeine.count >= 2 && withoutCaffeine.count >= 2 {
            let avgWith = withCaffeine.map { $0.score }.reduce(0, +) / withCaffeine.count
            let avgWithout = withoutCaffeine.map { $0.score }.reduce(0, +) / withoutCaffeine.count
            insights.append((factor: "Caffeine >200mg", emoji: "☕", avgScoreWith: avgWith, avgScoreWithout: avgWithout, countWith: withCaffeine.count))
        }

        let withExercise = trendRecords.filter { ($0.exerciseMinutes ?? 0) > 30 }
        let withoutExercise = trendRecords.filter { ($0.exerciseMinutes ?? 0) <= 30 }

        if withExercise.count >= 2 && withoutExercise.count >= 2 {
            let avgWith = withExercise.map { $0.score }.reduce(0, +) / withExercise.count
            let avgWithout = withoutExercise.map { $0.score }.reduce(0, +) / withoutExercise.count
            insights.append((factor: "Exercise >30min", emoji: "🏃", avgScoreWith: avgWith, avgScoreWithout: avgWithout, countWith: withExercise.count))
        }

        return insights
    }

    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Correlations")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(correlationInsights, id: \.factor) { insight in
                CorrelationTrendRow(
                    factor: insight.factor,
                    emoji: insight.emoji,
                    avgScoreWith: insight.avgScoreWith,
                    avgScoreWithout: insight.avgScoreWithout,
                    countWith: insight.countWith
                )
            }
        }
        .padding()
        .glassCard()
    }

    private var respiratoryTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Breathing Trends")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Image(systemName: "lungs.fill")
                    .foregroundColor(Theme.lightSleep)
                    .font(.caption)
            }

            let respRecords = trendRecords.filter { $0.respiratoryRateAvg != nil }
            let spo2Records = trendRecords.filter { $0.spo2Avg != nil }

            HStack(spacing: 20) {
                if !respRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        let avgResp = respRecords.compactMap { $0.respiratoryRateAvg }.reduce(0, +) / Double(respRecords.count)
                        Text(String(format: "%.0f", avgResp))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.lightSleep)
                        Text("avg breaths/min")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                        Text("\(respRecords.count) nights tracked")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary.opacity(0.6))
                    }
                }

                if !spo2Records.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        let avgSpO2 = spo2Records.compactMap { $0.spo2Avg }.reduce(0, +) / Double(spo2Records.count)
                        Text(String(format: "%.0f%%", avgSpO2))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(avgSpO2 >= 95 ? Theme.insightAccent : Theme.warningAccent)
                        Text("avg SpO₂")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                        let drops = spo2Records.flatMap { [$0.spo2DropsBelow90 ?? 0] }.reduce(0, +)
                        if drops > 0 {
                            Text("\(drops) drops <90%")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.heartRate)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
        .glassCard()
    }

    private func loadTrends() async {
        isLoading = true
        defer { isLoading = false }

        let days: Int
        switch selectedTimeRange {
        case .week: days = 7
        case .twoWeeks: days = 14
        case .thirtyDays: days = 30
        }

        let calendar = Calendar.current
        let now = Date()
        var records: [SleepRecord] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay: Date
            if dayOffset == 0 {
                endOfDay = now
            } else {
                endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            }

            do {
                if let record = try await healthKitService.fetchSleepForDate(startOfDay: startOfDay, endOfDay: endOfDay) {
                    records.append(record)
                }
            } catch {
                print("Failed to fetch sleep for \(date): \(error)")
            }
        }

        trendRecords = records.sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Types

struct MonthStats {
    let avgScore: Int
    let avgHours: Double
    let nights: Int

    init(from records: [SleepRecord]) {
        self.nights = records.count
        self.avgScore = records.isEmpty ? 0 : records.map { $0.score }.reduce(0, +) / records.count
        self.avgHours = records.isEmpty ? 0 : records.map { $0.totalDuration / 3600 }.reduce(0, +) / Double(records.count)
    }
}

struct MonthComparisonBox: View {
    let label: String
    let avgScore: Int
    let avgHours: Double
    let nights: Int
    let isBetter: Bool
    let hasData: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                if isBetter && hasData {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.insightAccent)
                }
            }

            if hasData {
                Text("\(avgScore)")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(Theme.scoreColor(for: avgScore))

                Text(String(format: "%.1fh avg", avgHours))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)

                Text("\(nights) nights")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
            } else {
                Text("—")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(Theme.textSecondary.opacity(0.5))

                Text("No data")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }
}

struct BestWorstBox: View {
    let label: String
    let score: Int
    let date: Date
    let hours: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }

            Text("\(score)")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(color)

            Text(formattedDate)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)

            Text(hours)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct TrendStatBox: View {
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

struct CorrelationTrendRow: View {
    let factor: String
    let emoji: String
    let avgScoreWith: Int
    let avgScoreWithout: Int
    let countWith: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(factor)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("With")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                        HStack(spacing: 2) {
                            Text("\(avgScoreWith)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.scoreColor(for: avgScoreWith))
                            Text("avg")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Without")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                        HStack(spacing: 2) {
                            Text("\(avgScoreWithout)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.scoreColor(for: avgScoreWithout))
                            Text("avg")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Spacer()

                    diffBadge
                }
            }
        }
        .padding(12)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var diffBadge: some View {
        let diff = avgScoreWith - avgScoreWithout
        let isPositive = diff > 0

        return HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .font(.system(size: 9, weight: .bold))
            Text("\(abs(diff))")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(isPositive ? Theme.insightAccent : Theme.heartRate)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isPositive ? Theme.insightAccent : Theme.heartRate).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
