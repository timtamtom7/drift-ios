import SwiftUI

/// Anonymous sleep community view with sleep comparisons and challenges.
struct SleepCommunityView: View {
    @State private var selectedTab: CommunityTab = .compare
    @State private var communityItems: [AnonymousSleepItem] = []

    enum CommunityTab: String, CaseIterable {
        case compare = "Compare"
        case challenges = "Challenges"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab bar
                    HStack(spacing: 0) {
                        ForEach(CommunityTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                        .foregroundColor(selectedTab == tab ? Theme.insightAccent : Theme.textSecondary)

                                    Rectangle()
                                        .fill(selectedTab == tab ? Theme.insightAccent : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Divider()
                        .background(Theme.textSecondary.opacity(0.1))

                    TabView(selection: $selectedTab) {
                        compareView.tag(CommunityTab.compare)
                        challengesView.tag(CommunityTab.challenges)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Compare View

    private var compareView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Anonymous comparison card
                anonymousComparisonCard

                // Your anonymized stats
                yourAnonymizedStats

                // Community sleep trends
                communityTrendsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var anonymousComparisonCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.insightAccent)

                    Text("How Do You Compare?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }

                Text("See how your sleep stacks up against anonymous users in your age group. No personal data is ever shared.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)

                Divider()
                    .background(Theme.textSecondary.opacity(0.1))

                VStack(spacing: 12) {
                    ComparisonRow(
                        label: "Average Sleep Score",
                        yourValue: "78",
                        communityAvg: "74",
                        unit: "pts"
                    )
                    ComparisonRow(
                        label: "Average Sleep Duration",
                        yourValue: "7.2h",
                        communityAvg: "7.0h",
                        unit: ""
                    )
                    ComparisonRow(
                        label: "Average Deep Sleep",
                        yourValue: "95m",
                        communityAvg: "88m",
                        unit: ""
                    )
                }
            }
            .padding(16)
        }
    }

    private var yourAnonymizedStats: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.insightAccent)

                    Text("Your Anonymized Profile")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }

                Text("Your data is shared as an anonymous aggregate. Your name, device, and specific data are never shared.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: 12) {
                    AnonymizedStatBadge(label: "Age Group", value: "25-34")
                    AnonymizedStatBadge(label: "Region", value: "North America")
                    AnonymizedStatBadge(label: "Sleep Type", value: "Consistent")
                }
            }
            .padding(16)
        }
    }

    private var communityTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Sleep Trends")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    TrendRow(
                        icon: "moon.fill",
                        title: "People sleep 20 min less on weekdays",
                        emoji: "📉"
                    )
                    Divider().background(Theme.textSecondary.opacity(0.1))
                    TrendRow(
                        icon: "figure.run",
                        title: "Exercise improves sleep score by 15%",
                        emoji: "🏃"
                    )
                    Divider().background(Theme.textSecondary.opacity(0.1))
                    TrendRow(
                        icon: "cup.and.saucer.fill",
                        title: "Late caffeine reduces deep sleep by 18%",
                        emoji: "☕"
                    )
                }
                .padding(16)
            }
        }
    }

    // MARK: - Challenges View

    private var challengesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Active challenges
                Text("Active Challenges")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ChallengeCard(
                    title: "7-Day Consistent Bedtime",
                    description: "Go to bed within 30 minutes of the same time for 7 nights",
                    participants: 1247,
                    daysLeft: 4,
                    progress: 0.43
                )

                ChallengeCard(
                    title: "30-Day Sleep Debt Reduction",
                    description: "Eliminate your accumulated sleep debt over 30 days",
                    participants: 834,
                    daysLeft: 18,
                    progress: 0.27
                )

                // Leaderboard
                Text("Anonymous Leaderboard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                GlassCard {
                    VStack(spacing: 0) {
                        LeaderboardRow(rank: 1, name: "Anonymous_4821", streak: "14 nights", score: "+22")
                        Divider().background(Theme.textSecondary.opacity(0.1))
                        LeaderboardRow(rank: 2, name: "Anonymous_7293", streak: "11 nights", score: "+18")
                        Divider().background(Theme.textSecondary.opacity(0.1))
                        LeaderboardRow(rank: 3, name: "Anonymous_1156", streak: "9 nights", score: "+15")
                        Divider().background(Theme.textSecondary.opacity(0.1))
                        LeaderboardRow(rank: 7, name: "You", streak: "5 nights", score: "+8", isYou: true)
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let label: String
    let yourValue: String
    let communityAvg: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text("You: \(yourValue)\(unit)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.insightAccent)

            Text("·")
                .foregroundColor(Theme.textSecondary)

            Text("Avg: \(communityAvg)\(unit)")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - Anonymized Stat Badge

struct AnonymizedStatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Trend Row

struct TrendRow: View {
    let icon: String
    let title: String
    let emoji: String

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 20))

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let title: String
    let description: String
    let participants: Int
    let daysLeft: Int
    let progress: Double

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Text("\(daysLeft) days left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.warningAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.warningAccent.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.surface)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.insightAccent)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)

                    Text("\(participants) participants")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Text("\(Int(progress * 100))% complete")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.insightAccent)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let streak: String
    let score: String
    var isYou: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(rankColor)
                .frame(width: 32)

            Text(name)
                .font(.system(size: 13, weight: isYou ? .semibold : .regular))
                .foregroundColor(isYou ? Theme.insightAccent : Theme.textPrimary)

            Spacer()

            Text(streak)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)

            Text(score)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700") // gold
        case 2: return Color(hex: "C0C0C0") // silver
        case 3: return Color(hex: "CD7F32") // bronze
        default: return Theme.textSecondary
        }
    }
}

// MARK: - Anonymous Sleep Item

struct AnonymousSleepItem: Identifiable {
    let id = UUID()
    let ageGroup: String
    let sleepScore: Int
    let sleepDuration: String
    let deepSleepMinutes: Int
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
    }
}
