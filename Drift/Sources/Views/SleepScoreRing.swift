import SwiftUI

struct SleepScoreRing: View {
    let score: Int
    @State private var animatedScore: Int = 0
    @State private var ringRotation: Double = -90
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Theme.surface,
                    lineWidth: 16
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    scoreGradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(ringRotation))
                .shadow(color: scoreColor.opacity(0.5), radius: 10, x: 0, y: 0)

            VStack(spacing: 4) {
                Text("\(animatedScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 1.2), value: animatedScore)

                Text("Sleep Score")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .padding(40)
        .onAppear {
            animatedScore = score
            withAnimation(.spring(duration: 1.4, bounce: 0.3)) {
                ringRotation = 270
            }
        }
        .onChange(of: score) { _, newValue in
            animatedScore = newValue
            withAnimation(.spring(duration: 1.2, bounce: 0.3)) {
                ringRotation = -90
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(duration: 1.4, bounce: 0.3)) {
                    ringRotation = 270
                }
            }
        }
    }

    private var progress: CGFloat {
        CGFloat(animatedScore) / 100.0
    }

    private var scoreColor: Color {
        Theme.scoreColor(for: score)
    }

    private var scoreGradient: LinearGradient {
        LinearGradient(
            colors: [scoreColor.opacity(0.8), scoreColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
