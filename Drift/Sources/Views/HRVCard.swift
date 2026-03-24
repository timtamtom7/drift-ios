import SwiftUI
import Charts

struct HRVCard: View {
    let record: SleepRecord
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if record.hrvAvg != nil {
                dataView
            } else {
                noDataErrorView
            }
        }
        .padding()
        .glassCard()
    }

    private var headerRow: some View {
        HStack {
            Text("Heart Rate Variability")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Spacer()

            if record.hrvAvg != nil {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var dataView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                HRVStatItem(
                    value: String(format: "%.0f", record.hrvAvg ?? 0),
                    unit: "ms",
                    label: "Avg HRV",
                    color: Theme.insightAccent
                )

                if let hrvAvg = record.hrvAvg {
                    HRVStatItem(
                        value: hrvRecoveryLabel(hrvAvg),
                        unit: "",
                        label: "Recovery",
                        color: hrvRecoveryColor(hrvAvg)
                    )
                }

                Spacer()

                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundColor(Theme.insightAccent.opacity(0.7))
            }

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var noDataErrorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "applewatch.slash.fill")
                    .foregroundColor(Theme.warningAccent)
                    .font(.caption)

                Text("No HRV data from your watch")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }

            Text("HRV requires Apple Watch to measure heartbeat intervals overnight. Make sure your watch is charged and Sleep Tracking is enabled in the Health app.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .lineSpacing(2)

            HStack(spacing: 12) {
                Button {
                    Task {
                        await healthKitService.fetchTodaySleep()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.deepSleep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                if healthKitService.hrvDataUnavailable {
                    Text("Watch may not support HRV tracking")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary.opacity(0.6))
                }
            }

            // Tip box
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.warningAccent)

                Text("Tip: HRV is typically available on Apple Watch Series 3 or later. Make sure watchOS is up to date.")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
                    .lineSpacing(1)
            }
            .padding(8)
            .background(Theme.warningAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(Theme.surface)

            Text("What is HRV?")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            Text("Heart Rate Variability measures the variation in time between heartbeats. Higher HRV generally indicates better cardiovascular fitness and recovery. It fluctuates with stress, sleep quality, and exercise.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.8))
                .lineSpacing(2)

            hrvContextView
        }
    }

    private var hrvContextView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Context")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("50+ ms")
                        .font(.system(size: 11, design: .monospaced).bold())
                        .foregroundColor(Theme.insightAccent)
                    Text("Excellent")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("30-50 ms")
                        .font(.system(size: 11, design: .monospaced).bold())
                        .foregroundColor(Theme.warningAccent)
                    Text("Normal")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("<30 ms")
                        .font(.system(size: 11, design: .monospaced).bold())
                        .foregroundColor(Theme.heartRate)
                    Text("Low")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func hrvRecoveryLabel(_ value: Double) -> String {
        if value >= 50 { return "Good" }
        if value >= 30 { return "Fair" }
        return "Low"
    }

    private func hrvRecoveryColor(_ value: Double) -> Color {
        if value >= 50 { return Theme.insightAccent }
        if value >= 30 { return Theme.warningAccent }
        return Theme.heartRate
    }
}

struct HRVStatItem: View {
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(color.opacity(0.7))
                }
            }

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

struct HRVTrendCard: View {
    let records: [SleepRecord]
    @State private var selectedRecord: SleepRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HRV Trend")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            let hrvRecords = records.filter { $0.hrvAvg != nil }

            if hrvRecords.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.title)
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("No HRV data yet")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                Chart {
                    ForEach(hrvRecords) { record in
                        LineMark(
                            x: .value("Date", record.date, unit: .day),
                            y: .value("HRV", record.hrvAvg ?? 0)
                        )
                        .foregroundStyle(Theme.insightAccent)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                        PointMark(
                            x: .value("Date", record.date, unit: .day),
                            y: .value("HRV", record.hrvAvg ?? 0)
                        )
                        .foregroundStyle(Theme.insightAccent)
                        .symbolSize(30)
                    }

                    if let avgHRV = averageHRV {
                        RuleMark(y: .value("Average", avgHRV))
                            .foregroundStyle(Theme.warningAccent.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.surface)
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.surface)
                        AxisValueLabel()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 120)

                HStack {
                    if let avgHRV = averageHRV {
                        Text("Avg: \(String(format: "%.0f", avgHRV)) ms")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Theme.warningAccent)
                    }

                    Spacer()

                    Text("\(hrvRecords.count) nights")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var averageHRV: Double? {
        let hrvRecords = records.filter { $0.hrvAvg != nil }
        guard !hrvRecords.isEmpty else { return nil }
        return hrvRecords.compactMap { $0.hrvAvg }.reduce(0, +) / Double(hrvRecords.count)
    }
}
