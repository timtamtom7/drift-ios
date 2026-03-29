import SwiftUI

struct SleepDashboardView: View {
    @State private var currentPhase: SleepPhase = .awake
    @State private var sleepScore: Int = 82
    @State private var sleepGoalHours: Double = 8.0
    @State private var currentSleepHours: Double = 6.5
    @State private var wakeUpTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var lastNightScore: Int = 78

    private var goalProgress: Double {
        min(currentSleepHours / sleepGoalHours, 1.0)
    }

    var body: some View {
        ZStack {
            // Deep purple gradient background
            LinearGradient(
                colors: [Theme.deepPurple, Color(hex: "0F0D1A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Current Phase Card
                    phaseCard

                    // Sleep Goal Progress Ring
                    sleepGoalCard

                    // Go to Sleep Button
                    goToSleepButton

                    // Wake-up Time Card
                    wakeUpCard

                    // Last Night Score
                    lastNightCard
                }
                .padding(16)
            }
        }
    }

    private var phaseCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: currentPhase.icon)
                    .font(.title2)
                    .foregroundStyle(Theme.purple)

                Text(currentPhase.rawValue)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Circle()
                    .fill(phaseColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: phaseColor.opacity(0.5), radius: 4)
            }

            Text(currentPhase.description)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private var phaseColor: Color {
        switch currentPhase {
        case .awake: return Theme.awake
        case .light: return Theme.lightSleep
        case .deep: return Theme.deepSleep
        case .rem: return Theme.remSleep
        }
    }

    private var sleepGoalCard: some View {
        VStack(spacing: 12) {
            Text("Tonight's Goal")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Theme.surfaceLight, lineWidth: 12)

                // Progress ring
                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.purple, Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.purple.opacity(0.4), radius: 6)

                VStack(spacing: 4) {
                    Text("\(Int(goalProgress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    Text("\(String(format: "%.1f", currentSleepHours)) / \(String(format: "%.0f", sleepGoalHours))h")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .frame(width: 120, height: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private var goToSleepButton: some View {
        Button {
            // Action to start sleep tracking
            currentPhase = .light
        } label: {
            HStack {
                Image(systemName: "bed.double.fill")
                Text("Go to Sleep")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Theme.purple, Color(hex: "8B5CF6")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Theme.purple.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var wakeUpCard: some View {
        HStack {
            Image(systemName: "alarm.fill")
                .foregroundStyle(Theme.warningAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Wake-up Time")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                Text(wakeUpTime, style: .time)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private var lastNightCard: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(Theme.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Last Night")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: 8) {
                    Text("\(lastNightScore)")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text("score")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            // Score indicator
            Circle()
                .fill(Theme.scoreColor(for: lastNightScore))
                .frame(width: 10, height: 10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}
