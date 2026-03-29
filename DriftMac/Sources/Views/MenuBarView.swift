import SwiftUI

struct MenuBarView: View {
    @Binding var showPopover: Bool
    @Binding var currentPhase: SleepPhase
    @Binding var sleepScore: Int

    @State private var isTracking = false

    var body: some View {
        VStack(spacing: 0) {
            // Compact Header
            HStack(spacing: 12) {
                // Phase indicator
                ZStack {
                    Circle()
                        .fill(phaseColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: currentPhase.icon)
                        .font(.title3)
                        .foregroundStyle(phaseColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentPhase.rawValue)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text(currentPhase.description)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                // Score badge
                VStack(spacing: 0) {
                    Text("\(sleepScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.scoreColor(for: sleepScore))

                    Text("score")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(14)

            Divider()
                .background(Theme.surfaceLight)

            // Quick Actions
            VStack(spacing: 4) {
                quickActionButton(
                    icon: isTracking ? "stop.fill" : "bed.double.fill",
                    title: isTracking ? "Stop Tracking" : "Start Sleep",
                    color: Theme.purple
                ) {
                    isTracking.toggle()
                    if isTracking {
                        currentPhase = .light
                    }
                }

                quickActionButton(
                    icon: "alarm.fill",
                    title: "Set Wake-up",
                    color: Theme.warningAccent
                ) {
                    // Open wake-up settings
                }

                Divider()
                    .background(Theme.surfaceLight)
                    .padding(.vertical, 4)

                quickActionButton(
                    icon: "chart.bar.fill",
                    title: "View History",
                    color: Theme.lightSleep
                ) {
                    // Open history
                }
            }
            .padding(.vertical, 8)

            Divider()
                .background(Theme.surfaceLight)

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                        .font(.caption)
                    Text("Quit Drift")
                        .font(.caption)
                }
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
        }
        .frame(width: 220)
        .background(Theme.surface)
    }

    private var phaseColor: Color {
        switch currentPhase {
        case .awake: return Theme.awake
        case .light: return Theme.lightSleep
        case .deep: return Theme.deepSleep
        case .rem: return Theme.remSleep
        }
    }

    private func quickActionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
