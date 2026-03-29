import SwiftUI
import Charts

struct DaySleepData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
    let score: Int
}

struct SleepHistoryView: View {
    @State private var weekData: [DaySleepData] = [
        DaySleepData(day: "Mon", hours: 6.2, score: 72),
        DaySleepData(day: "Tue", hours: 7.5, score: 85),
        DaySleepData(day: "Wed", hours: 8.1, score: 91),
        DaySleepData(day: "Thu", hours: 5.8, score: 65),
        DaySleepData(day: "Fri", hours: 7.2, score: 80),
        DaySleepData(day: "Sat", hours: 9.0, score: 95),
        DaySleepData(day: "Sun", hours: 7.8, score: 88)
    ]

    private var averageScore: Int {
        weekData.isEmpty ? 0 : weekData.reduce(0) { $0 + $1.score } / weekData.count
    }

    private var bestStreak: Int {
        var currentStreak = 0
        var best = 0
        for record in weekData {
            if record.score >= 80 {
                currentStreak += 1
                best = max(best, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return best
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.deepPurple, Color(hex: "0F0D1A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 7-Day Sleep Chart
                    chartCard

                    // Stats Row
                    statsRow
                }
                .padding(16)
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Sleep")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Chart(weekData) { data in
                BarMark(
                    x: .value("Day", data.day),
                    y: .value("Hours", data.hours)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.purple, Color(hex: "8B5CF6")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.surfaceLight)
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            // Average Score
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(Theme.purple)

                Text("\(averageScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("Avg Score")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            )

            // Best Streak
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.warningAccent)

                Text("\(bestStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
    }
}
