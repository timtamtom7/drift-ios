import SwiftUI

struct SleepStagesBar: View {
    let stages: [SleepStage]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sleep Stages")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            if stages.isEmpty {
                emptyBar
            } else {
                stackedBar
            }

            stageLegend
        }
    }

    private var emptyBar: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Theme.surface)
            .frame(height: 48)
            .overlay(
                Text("No stage data available")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            )
    }

    private var stackedBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(normalizedStages) { stage in
                    Rectangle()
                        .fill(stage.type.color)
                        .frame(width: max(geometry.size.width * (stage.duration / totalStageDuration), 2))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 48)
    }

    private var normalizedStages: [SleepStage] {
        stages.filter { $0.duration > 0 }
    }

    private var totalStageDuration: TimeInterval {
        normalizedStages.reduce(0) { $0 + $1.duration }
    }

    private var stageLegend: some View {
        HStack(spacing: 16) {
            ForEach(SleepStageType.allCases, id: \.self) { type in
                HStack(spacing: 4) {
                    Circle()
                        .fill(type.color)
                        .frame(width: 8, height: 8)
                    Text(type.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(minutesForStage(type))m")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
            }
        }
    }

    private func minutesForStage(_ type: SleepStageType) -> Int {
        stages.filter { $0.type == type }.reduce(0) { $0 + $1.durationMinutes }
    }
}
