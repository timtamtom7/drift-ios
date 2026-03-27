import SwiftUI

struct SleepScoreDetailView: View {
    let record: SleepRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundGradient],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Score breakdown header
                    VStack(spacing: 8) {
                        Text("Sleep Score Breakdown")
                            .font(.headline)
                            .foregroundColor(Theme.textSecondary)

                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 16)

                    // Ring with breakdown
                    SleepScoreRing(score: record.score)
                        .frame(height: 200)

                    // Score factors
                    VStack(spacing: 12) {
                        ScoreFactorRow(
                            title: "Duration",
                            value: record.totalHoursFormatted,
                            detail: durationDetail,
                            color: Theme.lightSleep
                        )

                        ScoreFactorRow(
                            title: "Deep Sleep",
                            value: "\(record.deepSleepMinutes)m",
                            detail: deepSleepDetail,
                            color: Theme.deepSleep
                        )

                        ScoreFactorRow(
                            title: "REM Sleep",
                            value: "\(record.remSleepMinutes)m",
                            detail: remSleepDetail,
                            color: Theme.remSleep
                        )

                        ScoreFactorRow(
                            title: "Awake Time",
                            value: "\(record.awakeMinutes)m",
                            detail: awakeDetail,
                            color: Theme.awake
                        )
                    }
                    .padding()
                    .glassCard()

                    // Sleep stages timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Timeline")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)

                        SleepStagesBar(stages: record.stages)
                            .frame(height: 80)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fell Asleep")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Text(formatTime(record.fellAsleepTime))
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.textPrimary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Woke Up")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Text(formatTime(record.wokeUpTime))
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .glassCard()

                    // Vitals if available
                    if record.heartRateMin != nil || record.hrvAvg != nil {
                        vitalsSection
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Sleep Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Vitals")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let hrMin = record.heartRateMin {
                    VitalCell(title: "Min HR", value: "\(hrMin)", unit: "bpm", color: Theme.heartRate)
                }
                if let hrMax = record.heartRateMax {
                    VitalCell(title: "Max HR", value: "\(hrMax)", unit: "bpm", color: Theme.heartRate)
                }
                if let hrAvg = record.heartRateAvg {
                    VitalCell(title: "Avg HR", value: "\(hrAvg)", unit: "bpm", color: Theme.heartRate)
                }
                if let hrv = record.hrvAvg {
                    VitalCell(title: "HRV Avg", value: String(format: "%.0f", hrv), unit: "ms", color: Theme.insightAccent)
                }
                if let resp = record.respiratoryRateAvg {
                    VitalCell(title: "Resp Rate", value: String(format: "%.1f", resp), unit: "brpm", color: Theme.deepSleep)
                }
                if let spo2 = record.spo2Avg {
                    VitalCell(title: "SpO₂ Avg", value: String(format: "%.0f", spo2), unit: "%", color: Theme.insightAccent)
                }
            }
        }
        .padding()
        .glassCard()
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

    private var durationDetail: String {
        let target = 8.0
        let actual = record.totalHours
        if actual >= target - 0.5 {
            return "Optimal duration"
        } else if actual >= target - 1.5 {
            return "Slightly short"
        } else {
            return "Below recommended"
        }
    }

    private var deepSleepDetail: String {
        let targetMinutes = Double(record.totalMinutes) * 0.2
        if Double(record.deepSleepMinutes) >= targetMinutes {
            return "Good deep sleep"
        } else {
            return "Could use more deep sleep"
        }
    }

    private var remSleepDetail: String {
        let targetMinutes = Double(record.totalMinutes) * 0.25
        if Double(record.remSleepMinutes) >= targetMinutes {
            return "Good REM sleep"
        } else {
            return "Could use more REM sleep"
        }
    }

    private var awakeDetail: String {
        if record.awakeMinutes <= 30 {
            return "Minimal interruptions"
        } else if record.awakeMinutes <= 60 {
            return "Some awakenings"
        } else {
            return "Many interruptions"
        }
    }

    private var totalMinutes: Int {
        Int(record.totalDuration / 60)
    }
}

struct ScoreFactorRow: View {
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

struct VitalCell: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
    }
}
