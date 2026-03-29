import SwiftUI

struct SleepGoalsView: View {
    @State private var bedtime: Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var sleepDebtHours: Double = 4.5
    @State private var weeklyGoalHours: Double = 56.0
    @State private var weeklySleptHours: Double = 48.5

    private var weeklyProgress: Double {
        min(weeklySleptHours / weeklyGoalHours, 1.0)
    }

    private var debtColor: Color {
        if sleepDebtHours <= 2 { return Theme.insightAccent }
        if sleepDebtHours <= 5 { return Theme.warningAccent }
        return Theme.heartRate
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
                    // Sleep/Wake Times
                    sleepScheduleCard

                    // Sleep Debt Tracker
                    sleepDebtCard

                    // Weekly Goal Progress
                    weeklyGoalCard
                }
                .padding(16)
            }
        }
    }

    private var sleepScheduleCard: some View {
        VStack(spacing: 16) {
            Text("Sleep Schedule")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                // Bedtime
                VStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.purple)

                    Text("Bedtime")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .scaleEffect(0.8)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Theme.surfaceLight)
                    .frame(width: 1, height: 80)

                // Wake Time
                VStack(spacing: 8) {
                    Image(systemName: "alarm.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.warningAccent)

                    Text("Wake-up")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)

                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .scaleEffect(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private var sleepDebtCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(debtColor)

                Text("Sleep Debt")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()
            }

            HStack(alignment: .bottom, spacing: 8) {
                Text(String(format: "%.1f", sleepDebtHours))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(debtColor)

                Text("hours")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Debt bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(debtColor)
                        .frame(width: geometry.size.width * min(sleepDebtHours / 10, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            Text("Above your target sleep duration")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private var weeklyGoalCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Theme.purple)

                Text("Weekly Goal")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text("\(String(format: "%.0f", weeklySleptHours)) / \(String(format: "%.0f", weeklyGoalHours))h")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Theme.surfaceLight, lineWidth: 10)

                Circle()
                    .trim(from: 0, to: weeklyProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.purple, Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.purple.opacity(0.4), radius: 4)

                VStack(spacing: 2) {
                    Text("\(Int(weeklyProgress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .frame(width: 100, height: 100)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}
