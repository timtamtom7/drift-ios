import SwiftUI

struct SleepStagesBar: View {
    let stages: [SleepStage]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sleep Stages")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                if !stages.isEmpty {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            if stages.isEmpty {
                emptyBar
            } else {
                stackedBar

                if isExpanded {
                    expandedStagesView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            stageLegend
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.3)) {
                isExpanded.toggle()
            }
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

    private var expandedStagesView: some View {
        VStack(spacing: 8) {
            ForEach(groupedStages, id: \.type) { group in
                HStack {
                    Circle()
                        .fill(group.type.color)
                        .frame(width: 10, height: 10)

                    Text(group.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Text("\(group.durationMinutes)m")
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .foregroundColor(group.type.color)

                    Text(String(format: "%.0f%%", group.percentage))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 8)
    }

    private var groupedStages: [StageGroup] {
        let total = totalStageDuration > 0 ? totalStageDuration : 1
        return SleepStageType.allCases.compactMap { type in
            let minutes = minutesForStage(type)
            guard minutes > 0 else { return nil }
            let duration = TimeInterval(minutes * 60)
            return StageGroup(
                type: type,
                durationMinutes: minutes,
                percentage: (duration / total) * 100
            )
        }
    }

    private func minutesForStage(_ type: SleepStageType) -> Int {
        stages.filter { $0.type == type }.reduce(0) { $0 + $1.durationMinutes }
    }
}

struct StageGroup {
    let type: SleepStageType
    let durationMinutes: Int
    let percentage: Double
}
