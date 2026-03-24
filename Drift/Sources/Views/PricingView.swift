import SwiftUI

struct PricingView: View {
    @Binding var isPresented: Bool
    @State private var selectedTier: PricingTier = .insights

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    headerSection

                    tierSelector

                    tierDetail

                    CTAButton(tier: selectedTier, isPresented: $isPresented)

                    termsNote
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.deepSleep, Theme.remSleep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Unlock Deeper Insights")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            Text("Choose the plan that fits your rest.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var tierSelector: some View {
        HStack(spacing: 0) {
            ForEach(PricingTier.allCases, id: \.self) { tier in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedTier = tier
                    }
                } label: {
                    Text(tier.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTier == tier ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTier == tier ?
                            AnyShapeStyle(LinearGradient(
                                colors: [Theme.deepSleep, Theme.remSleep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )) : AnyShapeStyle(Color.clear)
                        )
                }
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tierDetail: some View {
        VStack(spacing: 0) {
            // Price
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(selectedTier.price)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("/month")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.top, 8)

            if selectedTier != .free {
                Text("Cancel anytime")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, 4)
            }

            Divider()
                .background(Theme.surface)
                .padding(.vertical, 20)

            // Features
            VStack(alignment: .leading, spacing: 14) {
                ForEach(selectedTier.features, id: \.text) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(24)
        .glassCard()
    }

    private var termsNote: some View {
        Text("Subscriptions auto-renew unless cancelled 24h before the period ends. By subscribing you agree to our Terms of Service and Privacy Policy.")
            .font(.system(size: 11))
            .foregroundColor(Theme.textSecondary.opacity(0.7))
            .multilineTextAlignment(.center)
    }
}

// MARK: - CTA Button
struct CTAButton: View {
    let tier: PricingTier
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            if tier == .free {
                isPresented = false
            } else {
                // In a real app, this would trigger StoreKit
                // For now, dismiss and store preference
                UserDefaults.standard.set(tier.rawValue, forKey: "selectedPlan")
                isPresented = false
            }
        } label: {
            Text(buttonText)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    tier == .free ? AnyShapeStyle(Theme.surface) :
                    AnyShapeStyle(LinearGradient(
                        colors: [Theme.deepSleep, Theme.remSleep],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var buttonText: String {
        switch tier {
        case .free: return "Continue with Free"
        case .insights: return "Start Insights Trial"
        case .complete: return "Start Complete Trial"
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let feature: TierFeature

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feature.included ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(feature.included ? Theme.insightAccent : Theme.textSecondary.opacity(0.4))

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.text)
                    .font(.subheadline)
                    .foregroundColor(feature.included ? Theme.textPrimary : Theme.textSecondary)

                if let sub = feature.subtext {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Pricing Tier
enum PricingTier: String, CaseIterable {
    case free = "free"
    case insights = "insights"
    case complete = "complete"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .insights: return "Insights"
        case .complete: return "Complete"
        }
    }

    var price: String {
        switch self {
        case .free: return "$0"
        case .insights: return "$5.99"
        case .complete: return "$11.99"
        }
    }

    var features: [TierFeature] {
        switch self {
        case .free:
            return [
                TierFeature(text: "7-day sleep history", subtext: nil, included: true),
                TierFeature(text: "Basic sleep stats", subtext: "Total time, sleep/wake times", included: true),
                TierFeature(text: "Sleep stages visualization", subtext: nil, included: true),
                TierFeature(text: "AI-generated insights", subtext: nil, included: false),
                TierFeature(text: "Heart rate analysis", subtext: nil, included: false),
                TierFeature(text: "Pattern detection", subtext: nil, included: false),
            ]

        case .insights:
            return [
                TierFeature(text: "30-day sleep history", subtext: nil, included: true),
                TierFeature(text: "Weekly AI insights", subtext: "Personalized patterns and tips", included: true),
                TierFeature(text: "Heart rate analysis", subtext: "Min, max, avg overnight", included: true),
                TierFeature(text: "Sleep stages breakdown", subtext: nil, included: true),
                TierFeature(text: "Trend charts", subtext: nil, included: true),
                TierFeature(text: "Family sharing", subtext: nil, included: false),
            ]

        case .complete:
            return [
                TierFeature(text: "Unlimited sleep history", subtext: nil, included: true),
                TierFeature(text: "Advanced pattern detection", subtext: "Correlation with lifestyle factors", included: true),
                TierFeature(text: "Family sharing", subtext: "Up to 5 members", included: true),
                TierFeature(text: "Consultation recommendations", subtext: "When to see a sleep specialist", included: true),
                TierFeature(text: "Full heart rate analysis", subtext: "With HRV insights", included: true),
                TierFeature(text: "Daily AI insights", subtext: "Priority access", included: true),
            ]
        }
    }
}

struct TierFeature {
    let text: String
    let subtext: String?
    let included: Bool
}
