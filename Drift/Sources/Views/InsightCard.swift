import SwiftUI

struct InsightCard: View {
    let insight: SleepInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(insight.isPositive ? Theme.insightAccent : Theme.warningAccent)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("💡")
                        .font(.system(size: 14))
                    Text("Insight")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }

                Text(insight.text)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .glassCard()
    }
}
