import SwiftUI

/// Comprehensive AI sleep insights view with score ring, recommendations, and weekly narrative.
struct SleepInsightsView: View {
    let record: SleepRecord
    let analysis: DeepSleepAnalysis
    let weeklyNarrative: WeeklySleepNarrative

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sleep score ring (using existing component)
                SleepScoreRing(score: record.score)
                    .padding(.top, 16)

                // AI narrative
                narrativeCard

                // Weekly stats grid
                weeklyStatsGrid

                // Sleep debt card
                sleepDebtCard

                // Best sleep window
                if let window = analysis.bestSleepWindow {
                    bestWindowCard(window: window)
                }

                // Detected patterns
                if !analysis.detectedPatterns.isEmpty {
                    patternsSection
                }

                // Recommendations
                if !analysis.recommendations.isEmpty {
                    recommendationsSection
                }

                // Breathing assessment
                if let snoring = analysis.snoringRisk {
                    breathingCard(risk: snoring, regularity: analysis.breathingRegularity)
                }

                // Predicted next score
                if let predicted = analysis.predictedNextScore {
                    predictedScoreCard(score: predicted)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.background)
    }

    // MARK: - Narrative Card

    private var narrativeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.insightAccent)

                    Text("AI Analysis")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Text(weeklyNarrative.trend)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(trendColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(trendColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(weeklyNarrative.narrative)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
    }

    // MARK: - Weekly Stats Grid

    private var weeklyStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCell(
                value: "\(weeklyNarrative.averageScore)",
                label: "Avg Score",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Theme.insightAccent
            )
            StatCell(
                value: "\(weeklyNarrative.nightsWith7HoursPlus)/\(weeklyNarrative.totalNights)",
                label: "7hr+ Nights",
                icon: "moon.fill",
                iconColor: Theme.remSleep
            )
            StatCell(
                value: "\(analysis.sleepStagesSummary.first { $0.stage == "deep" }?.avgMinutes ?? 0)m",
                label: "Avg Deep",
                icon: "zzz",
                iconColor: Theme.deepSleep
            )
        }
    }

    // MARK: - Sleep Debt Card

    private var sleepDebtCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.insightAccent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "battery.50")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.insightAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sleep Debt")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Text(analysis.sleepDebtFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                if analysis.sleepDebtMinutes > 30 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.warningAccent)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Best Window Card

    private func bestWindowCard(window: String) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.insightAccent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "clock")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.insightAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Best Sleep Window")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Text(window)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Patterns Section

    private var patternsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.insightAccent)

                    Text("Detected Patterns")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(analysis.detectedPatterns, id: \.self) { pattern in
                        Text(pattern)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.insightAccent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.yellow)

                    Text("Recommendations")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }

                ForEach(analysis.recommendations, id: \.self) { rec in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.insightAccent)
                            .padding(.top, 2)

                        Text(rec)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Breathing Card

    private func breathingCard(risk: String, regularity: String?) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(riskColor(risk).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "lungs.fill")
                        .font(.system(size: 18))
                        .foregroundColor(riskColor(risk))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Breathing Assessment")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    HStack(spacing: 8) {
                        Text("Snoring Risk: \(risk)")
                            .font(.system(size: 13))
                            .foregroundColor(riskColor(risk))

                        if let regularity = regularity {
                            Text("· \(regularity)")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Predicted Score Card

    private func predictedScoreCard(score: Int) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.insightAccent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.insightAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Predicted Next Score")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Text("\(score) / 100")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Helpers

    private var trendColor: Color {
        switch weeklyNarrative.trend {
        case "Improving": return .green
        case "Declining": return Theme.heartRate
        default: return Theme.insightAccent
        }
    }

    private func riskColor(_ risk: String) -> Color {
        switch risk {
        case "High": return Theme.heartRate
        case "Medium": return Theme.warningAccent
        default: return Theme.insightAccent
        }
    }
}

// MARK: - Stat Cell

struct StatCell: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}
