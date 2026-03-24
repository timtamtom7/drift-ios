import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1()
                    .tag(0)

                OnboardingPage2()
                    .tag(1)

                OnboardingPage3()
                    .tag(2)

                OnboardingPage4(isCompleted: $isCompleted)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack {
                Spacer()

                pageIndicator

                if currentPage < 3 {
                    skipButton
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Theme.deepSleep : Theme.surface)
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.3 : 1.0)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
    }

    private var skipButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("Skip")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, 24)
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        isCompleted = true
    }
}

// MARK: - Page 1: Concept
struct OnboardingPage1: View {
    @State private var starOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            NightSkyGraphic()
                .frame(height: 320)
                .padding(.horizontal, 40)

            VStack(spacing: 16) {
                Text("Sleep better,")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("live better.")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Drift tracks your sleep every night and tells you what it means — in plain English, not just numbers.")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 48)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 2: Apple Watch
struct OnboardingPage2: View {
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            WatchPhoneGraphic()
                .frame(height: 300)
                .padding(.horizontal, 40)

            VStack(spacing: 16) {
                Text("Works with your\nApple Watch")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your Apple Watch records sleep automatically. Just wear it to bed — Drift reads the data from Apple Health.")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                HStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .foregroundColor(Theme.deepSleep)
                    Text("Apple Watch required")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, 8)
            }
            .padding(.top, 48)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 3: Sleep Stages
struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            SleepStagesPreview()
                .frame(height: 280)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                Text("Understand your nights")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("Sleep isn't one thing. Deep sleep repairs your body. REM sharpens your mind. Drift shows you the full picture.")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 10) {
                    StageLabel(type: .deep, description: "Restores your body")
                    StageLabel(type: .rem, description: "Sharpens your mind")
                    StageLabel(type: .light, description: "Helps memory")
                    StageLabel(type: .awake, description: "Natural breaks")
                }
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }
            .padding(.top, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 4: Start Tracking
struct OnboardingPage4: View {
    @Binding var isCompleted: Bool
    @State private var scoreValue = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            OnboardingSleepScoreRing(score: scoreValue)
                .frame(height: 220)
                .padding(.horizontal, 60)

            VStack(spacing: 16) {
                Text("Wake up to insights")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("Every morning, your sleep score and an AI-generated insight — like knowing why you felt off today.")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 48)

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Start Tracking")
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.4).delay(0.5)) {
                scoreValue = 87
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        isCompleted = true
    }
}

// MARK: - Supporting Views
struct StageLabel: View {
    let type: SleepStageType
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(type.color)
                .frame(width: 12, height: 12)

            Text(type.rawValue)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 50, alignment: .leading)

            Text(description)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

struct OnboardingSleepScoreRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surface, lineWidth: 14)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    LinearGradient(
                        colors: [Theme.insightAccent, Theme.deepSleep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.insightAccent.opacity(0.4), radius: 12)

            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text("Your score tomorrow")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
        }
        .padding(40)
    }
}

// MARK: - Night Sky Graphic
struct NightSkyGraphic: View {
    @State private var stars: [(id: Int, x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient sky
                RadialGradient(
                    colors: [
                        Color(hex: "1e1b4b").opacity(0.6),
                        Theme.background
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.8
                )

                // Stars
                ForEach(stars, id: \.id) { star in
                    StarView(delay: star.delay)
                        .position(x: star.x * geometry.size.width, y: star.y * geometry.size.height)
                }

                // Moon
                MoonView()
                    .position(x: geometry.size.width * 0.75, y: geometry.size.height * 0.22)
            }
        }
        .onAppear {
            stars = (0..<45).map { i in
                (id: i, x: CGFloat.random(in: 0.05...0.95), y: CGFloat.random(in: 0.05...0.9), size: CGFloat.random(in: 1...3), delay: Double.random(in: 0...2))
            }
        }
    }
}

struct StarView: View {
    let delay: Double
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(Color.white)
            .opacity(opacity)
            .frame(width: 2, height: 2)
            .onAppear {
                withAnimation(.easeIn(duration: 1.5).delay(delay)) {
                    opacity = Double.random(in: 0.3...1.0)
                }
            }
    }
}

struct MoonView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "e2e8f0"))
                .frame(width: 60, height: 60)
                .shadow(color: Color.white.opacity(0.3), radius: 20)

            Circle()
                .fill(Theme.background)
                .frame(width: 52, height: 52)
                .offset(x: 8, y: -4)
        }
    }
}

// MARK: - Watch + Phone Graphic
struct WatchPhoneGraphic: View {
    @State private var pulse = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // iPhone
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "1e293b"))
                        .frame(width: 120, height: 240)

                    RoundedRectangle(cornerRadius: 22)
                        .fill(Theme.background)
                        .frame(width: 108, height: 210)

                    // Sleep ring preview
                    ZStack {
                        Circle()
                            .stroke(Theme.surface, lineWidth: 6)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: 0.78)
                            .stroke(Theme.deepSleep, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("7h 23m")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            Text("score 87")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    // Dynamic island
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black)
                        .frame(width: 50, height: 18)
                        .offset(y: -105)
                }

                // Phone home indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "475569"))
                    .frame(width: 80, height: 4)
                    .offset(y: 4)
            }

            Spacer()

            // Apple Watch
            VStack {
                ZStack {
                    // Band top
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "1e293b"))
                        .frame(width: 50, height: 40)
                        .offset(y: -50)

                    // Watch body
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: "1e293b"))
                        .frame(width: 90, height: 100)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.background)
                        .frame(width: 82, height: 92)

                    // Watch screen content
                    VStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.deepSleep)

                        Text("Sleep")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }

                    // Crown
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "334155"))
                        .frame(width: 6, height: 20)
                        .offset(x: 48, y: -5)

                    // Side button
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "334155"))
                        .frame(width: 4, height: 12)
                        .offset(x: 48, y: 10)

                    // Band bottom
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "1e293b"))
                        .frame(width: 50, height: 50)
                        .offset(y: 55)
                }

                // Pulse indicator
                Circle()
                    .fill(Theme.insightAccent)
                    .frame(width: 12, height: 12)
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .opacity(pulse ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .offset(y: -8)
            }
            .offset(x: -10)
        }
        .padding(.horizontal, 20)
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Sleep Stages Preview (animated bar for onboarding)
struct SleepStagesPreview: View {
    @State private var animated = false

    let stages: [(type: SleepStageType, ratio: CGFloat)] = [
        (.light, 0.08), (.deep, 0.18), (.rem, 0.22), (.light, 0.15),
        (.deep, 0.12), (.awake, 0.03), (.rem, 0.14), (.light, 0.08)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        Rectangle()
                            .fill(stage.type.color)
                            .frame(width: geo.size.width * stage.ratio * (animated ? 1 : 0))
                            .animation(.spring(duration: 0.8).delay(Double(index) * 0.08), value: animated)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(height: 56)

            // Time labels
            HStack {
                Text("10:30 PM")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("6:45 AM")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }

            // Legend
            HStack(spacing: 16) {
                ForEach([SleepStageType.deep, .rem, .light, .awake], id: \.self) { type in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(type.color)
                            .frame(width: 10, height: 10)
                        Text(type.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            animated = true
        }
    }
}
