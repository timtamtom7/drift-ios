import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var healthKitAuthorized = false
    var onCompleted: (() -> Void)?

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars.fill",
            title: "Track Your Sleep",
            description: "Wear your Apple Watch to bed and let Drift automatically track your sleep stages, heart rate, and more."
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "AI-Powered Insights",
            description: "Get personalized recommendations based on your sleep patterns and lifestyle factors."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "See Your Trends",
            description: "Understand how your sleep evolves over time with beautiful charts and weekly reports."
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundGradient],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        Theme.haptic(.light)
                        onCompleted?()
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .accessibilityLabel("Skip onboarding")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Theme.deepSleep : Theme.surface)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.vertical, 24)

                // CTA Button
                Button {
                    Theme.haptic(.medium)
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        requestHealthKitAccess()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Theme.deepSleep, Theme.remSleep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
                }
                .padding(.horizontal, 24)
                .accessibilityLabel(currentPage < pages.count - 1 ? "Continue to next page" : "Get started with Drift")

                Spacer()
                    .frame(height: 48)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.deepSleep, Theme.remSleep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundColor(Theme.textPrimary)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private func requestHealthKitAccess() {
        Task {
            onCompleted?()
            dismiss()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}
