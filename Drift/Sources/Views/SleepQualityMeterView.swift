import SwiftUI

struct SleepQualityMeterView: View {
    let score: Int

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background arc
                ArcShape(startAngle: .degrees(135), endAngle: .degrees(405))
                    .stroke(Theme.surface, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 180, height: 180)

                // Foreground arc
                ArcShape(startAngle: .degrees(135), endAngle: .degrees(135 + scoreAngle))
                    .stroke(
                        LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: gradientEnd.opacity(0.6), radius: 12, x: 0, y: 0)

                // Tick marks
                ForEach(0..<5) { i in
                    TickMark(angle: 135 + Double(i) * 67.5, radius: 82)
                }

                // Score label
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .contentTransition(.numericText())

                    Text(scoreLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(scoreColor)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }

            // Quality bars
            HStack(spacing: 8) {
                QualityBar(label: "Duration", value: 0.85, color: Theme.lightSleep)
                QualityBar(label: "Deep", value: 0.72, color: Theme.deepSleep)
                QualityBar(label: "REM", value: 0.65, color: Theme.remSleep)
                QualityBar(label: "Rest", value: 0.90, color: Theme.insightAccent)
            }
            .padding(.horizontal, 8)
        }
    }

    private var scoreAngle: Double {
        (Double(score) / 100.0) * 270.0
    }

    private var scoreColor: Color {
        Theme.scoreColor(for: score)
    }

    private var gradientStart: Color {
        Theme.scoreColor(for: max(0, score - 20))
    }

    private var gradientEnd: Color {
        Theme.scoreColor(for: score)
    }

    private var scoreLabel: String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85: return "Good"
        case 55..<70: return "Fair"
        case 40..<55: return "Poor"
        default: return "Very Poor"
        }
    }
}

struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

struct TickMark: View {
    let angle: Double
    let radius: CGFloat

    var body: some View {
        VStack {
            Rectangle()
                .fill(Theme.textSecondary.opacity(0.4))
                .frame(width: 2, height: 8)
        }
        .offset(y: -radius)
        .rotationEffect(.degrees(angle))
    }
}

struct QualityBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surface)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: geo.size.height * CGFloat(value))
                }
            }
            .frame(height: 60)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - Empty State Illustration

struct EmptySleepIllustration: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Theme.deepSleep.opacity(0.5), Theme.remSleep.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "moon.stars")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Sleep Data")
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)

                Text("Wear your Apple Watch to bed and sync in the morning.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Family Comparison Chart Illustration

struct FamilyComparisonChartView: View {
    let familyScore: FamilySleepScore
    let yourScore: Int
    let partnerScore: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Comparison")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(alignment: .bottom, spacing: 24) {
                ComparisonBar(label: "You", score: yourScore, color: Theme.deepSleep)
                ComparisonBar(label: "Partner", score: partnerScore, color: Theme.remSleep)
                ComparisonBar(label: "Family", score: familyScore.aggregateScore, color: Theme.insightAccent)
            }
            .frame(height: 140)
            .padding(.horizontal, 8)

            HStack {
                Circle().fill(Theme.deepSleep).frame(width: 8, height: 8)
                Text("You").font(.caption).foregroundColor(Theme.textSecondary)
                Spacer()
                Circle().fill(Theme.remSleep).frame(width: 8, height: 8)
                Text("Partner").font(.caption).foregroundColor(Theme.textSecondary)
                Spacer()
                Circle().fill(Theme.insightAccent).frame(width: 8, height: 8)
                Text("Family").font(.caption).foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ComparisonBar: View {
    let label: String
    let score: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.surface)
                    .frame(width: 48, height: 100)

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 48, height: CGFloat(score))
                    .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 0)

                Text("\(score)")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(.white)
                    .offset(y: -CGFloat(score) - 8)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
