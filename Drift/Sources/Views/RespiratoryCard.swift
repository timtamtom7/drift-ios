import SwiftUI

struct RespiratoryCard: View {
    let record: SleepRecord
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Breathing & Oxygen")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Button {
                    Theme.haptic(.light)
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
                .accessibilityLabel(isExpanded ? "Collapse breathing details" : "Expand breathing details")
            }

            if healthKitService.respiratoryDataUnavailable {
                unavailableState
            } else {
                dataAvailableState
            }
        }
        .padding()
        .glassCard()
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.warningAccent)
                    .font(.caption)

                Text("No breathing or SpO₂ data from your watch")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Text("Make sure your Apple Watch is fitted snugly and that overnight SpO₂ tracking is enabled in the Health app.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .lineSpacing(2)

            Button {
                Theme.haptic(.light)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.deepSleep)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
            }
            .accessibilityLabel("Refresh breathing data")
        }
    }

    @ViewBuilder
    private var dataAvailableState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // SpO2
                if let spo2 = record.spo2Avg {
                    SpO2StatItem(
                        value: String(format: "%.0f", spo2),
                        unit: "%",
                        dropsBelow90: record.spo2DropsBelow90 ?? 0,
                        color: spo2Color(spo2)
                    )
                }

                Divider()
                    .background(Theme.surface)
                    .frame(height: 40)

                // Respiratory Rate
                if let respRate = record.respiratoryRateAvg {
                    RespiratoryStatItem(
                        value: String(format: "%.0f", respRate),
                        unit: "bpm",
                        color: Theme.lightSleep
                    )
                }

                Spacer()

                Image(systemName: "lungs.fill")
                    .font(.title2)
                    .foregroundColor(Theme.lightSleep.opacity(0.7))
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Theme.surface)

                    if let spo2 = record.spo2Avg {
                        spo2DetailView(spo2: spo2)
                    }

                    if let respRate = record.respiratoryRateAvg {
                        respRateDetailView(respRate: respRate)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var spo2Color: (Double) -> Color {
        { spo2 in
            if spo2 >= 95 { return Theme.insightAccent }
            if spo2 >= 90 { return Theme.warningAccent }
            return Theme.heartRate
        }
    }

    private func spo2DetailView(spo2: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Blood Oxygen (SpO₂)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            Text("Your blood oxygen remained at an average of \(String(format: "%.0f", spo2))% overnight. Normal is 95-100%. Values below 90% may indicate sleep apnea.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.8))
                .lineSpacing(2)

            if let drops = record.spo2DropsBelow90, drops > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.heartRate)
                    Text("\(drops) drop\(drops == 1 ? "" : "s") below 90% — worth discussing with a doctor.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.heartRate.opacity(0.9))
                }
            }
        }
    }

    private func respRateDetailView(respRate: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Respiratory Rate")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            Text("Your average respiratory rate was \(String(format: "%.0f", respRate)) breaths per minute. Normal resting range is 12-20 breaths per minute.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.8))
                .lineSpacing(2)

            if respRate > 20 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.warningAccent)
                    Text("Elevated rate — could indicate congestion, asthma, or stress.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.warningAccent.opacity(0.9))
                }
            } else if respRate < 12 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.insightAccent)
                    Text("Lower than average — this can be a sign of good cardiovascular fitness.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.insightAccent.opacity(0.9))
                }
            }
        }
    }
}

struct SpO2StatItem: View {
    let value: String
    let unit: String
    let dropsBelow90: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(color.opacity(0.7))
            }

            Text("SpO₂")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            if dropsBelow90 > 0 {
                Text("\(dropsBelow90) drops <90%")
                    .font(.caption2)
                    .foregroundColor(Theme.heartRate.opacity(0.8))
            }
        }
    }
}

struct RespiratoryStatItem: View {
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(color.opacity(0.7))
            }

            Text("Resp. Rate")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - HRV Trend Chart (dedicated full-screen view)

struct HRVTrendChartView: View {
    let records: [SleepRecord]
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
                        hrvOverviewCard
                        hrvTrendChartCard
                        hrvContextCard
                    }
                    .padding()
                }
            }
            .navigationTitle("HRV Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Theme.haptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .accessibilityLabel("Close HRV analysis")
                }
            }
        }
    }

    private var hrvRecords: [SleepRecord] {
        records.filter { $0.hrvAvg != nil }
    }

    private var averageHRV: Double? {
        guard !hrvRecords.isEmpty else { return nil }
        return hrvRecords.compactMap { $0.hrvAvg }.reduce(0, +) / Double(hrvRecords.count)
    }

    private var hrvOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            if let avg = averageHRV {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline) {
                            Text(String(format: "%.0f", avg))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(hrvColor(avg))
                            Text("ms")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(hrvColor(avg).opacity(0.7))
                        }
                        Text("Average HRV")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(hrvColor(avg))
                                .frame(width: 8, height: 8)
                            Text(hrvLabel(avg))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(hrvColor(avg))
                        }
                        Text("\(hrvRecords.count) nights tracked")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            } else {
                Text("No HRV data available")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .glassCard()
    }

    private var hrvTrendChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HRV Trend")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            if hrvRecords.isEmpty {
                emptyChartState
            } else {
                HRVTrendCard(records: records)
            }
        }
        .padding()
        .glassCard()
    }

    private var emptyChartState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary.opacity(0.4))

            Text("No HRV data available")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            Text("Wear your Apple Watch to bed to start tracking Heart Rate Variability.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var hrvContextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.deepSleep)
                Text("What is HRV?")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            Text("Heart Rate Variability (HRV) measures the variation in time between consecutive heartbeats. It's a key indicator of your autonomic nervous system balance — how well your body handles stress and recovers.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary.opacity(0.8))
                .lineSpacing(3)

            Divider().background(Theme.surface)

            Text("What affects HRV?")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                HRLFactorRow(emoji: "💪", factor: "Exercise", description: "Regular exercise improves HRV over time")
                HRLFactorRow(emoji: "😴", factor: "Sleep", description: "Poor sleep lowers HRV the next day")
                HRLFactorRow(emoji: "☕", factor: "Caffeine", description: "Can temporarily suppress HRV")
                HRLFactorRow(emoji: "🍷", factor: "Alcohol", description: "Significantly reduces HRV overnight")
                HRLFactorRow(emoji: "🧘", factor: "Stress", description: "Chronic stress lowers baseline HRV")
            }
        }
        .padding()
        .glassCard()
    }

    private func hrvColor(_ value: Double) -> Color {
        if value >= 50 { return Theme.insightAccent }
        if value >= 30 { return Theme.warningAccent }
        return Theme.heartRate
    }

    private func hrvLabel(_ value: Double) -> String {
        if value >= 50 { return "Excellent" }
        if value >= 30 { return "Normal" }
        return "Low"
    }
}

struct HRLFactorRow: View {
    let emoji: String
    let factor: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
                .font(.system(size: 12))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(factor)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
            }
        }
    }
}
