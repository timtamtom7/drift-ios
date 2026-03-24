import SwiftUI
import Charts

struct HRVCard: View {
    let record: SleepRecord
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Heart Rate Variability")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

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

            if let hrvAvg = record.hrvAvg {
                HStack(spacing: 16) {
                    HRVStatItem(
                        value: String(format: "%.0f", hrvAvg),
                        unit: "ms",
                        label: "Avg HRV",
                        color: Theme.insightAccent
                    )

                    if hrvAvg >= 50 {
                        HRVStatItem(
                            value: "Good",
                            unit: "",
                            label: "Recovery",
                            color: Theme.insightAccent
                        )
                    } else if hrvAvg >= 30 {
                        HRVStatItem(
                            value: "Fair",
                            unit: "",
                            label: "Recovery",
                            color: Theme.warningAccent
                        )
                    } else {
                        HRVStatItem(
                            value: "Low",
                            unit: "",
                            label: "Recovery",
                            color: Theme.heartRate
                        )
                    }

                    Spacer()

                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundColor(Theme.insightAccent.opacity(0.7))
                }

                if isExpanded {
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.warningAccent)
                        .font(.caption)

                    Text("No HRV data available from your watch")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding()
        .glassCard()
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
