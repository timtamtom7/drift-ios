import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var familyService = FamilyService()
    @State private var showAddMember = false
    @State private var showShareLink = false
    @State private var showComparison = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    if familyService.familyMembers.isEmpty {
                        emptyFamilyView
                    } else {
                        familyContentView
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMember = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(Theme.deepSleep)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showShareLink = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .disabled(familyService.familyMembers.isEmpty)
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberView(familyService: familyService)
            }
            .sheet(isPresented: $showShareLink) {
                ShareFamilyLinkView(familyService: familyService)
            }
            .sheet(isPresented: $showComparison) {
                FamilyComparisonView(familyService: familyService, records: healthKitService.weeklySleep)
            }
        }
    }

    private var emptyFamilyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.deepSleep.opacity(0.6), Theme.remSleep.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Family Sleep")
                    .font(.title2.bold())
                    .foregroundColor(Theme.textPrimary)

                Text("Compare sleep patterns with your partner or family members. See how everyone sleeps.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showAddMember = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                    Text("Add Family Member")
                }
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
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
        }
    }

    private var familyContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Family Sleep Score Card
                if let score = familyService.familySleepScore {
                    FamilySleepScoreCard(score: score)
                }

                // Tab selector for connected/pending
                Picker("View", selection: $selectedTab) {
                    Text("Connected").tag(0)
                    Text("Pending").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == 0 {
                    connectedMembersView
                } else {
                    pendingMembersView
                }

                // Compare Button
                if let partner = familyService.getPartner(), familyService.familyMembers.filter({ $0.isConnected }).count >= 2 {
                    Button {
                        showComparison = true
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Compare Sleep Patterns")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Theme.deepSleep, Theme.remSleep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .onAppear {
            familyService.calculateFamilySleepScore(records: healthKitService.weeklySleep)
            familyService.generateComparisons(records: healthKitService.weeklySleep)
        }
    }

    private var connectedMembersView: some View {
        let connected = familyService.familyMembers.filter { $0.isConnected }

        return VStack(spacing: 12) {
            ForEach(connected) { member in
                FamilyMemberRow(member: member, familyService: familyService)
            }
        }
        .padding(.horizontal)
    }

    private var pendingMembersView: some View {
        let pending = familyService.familyMembers.filter { !$0.isConnected }

        return VStack(spacing: 12) {
            if pending.isEmpty {
                Text("No pending invitations")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 24)
            } else {
                ForEach(pending) { member in
                    PendingMemberRow(member: member, familyService: familyService)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Family Sleep Score Card

struct FamilySleepScoreCard: View {
    let score: FamilySleepScore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Sleep Score")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Text(score.scoreGrade)
                        .font(.title.bold())
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Theme.surface, lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.aggregateScore) / 100)
                        .stroke(scoreGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(score.aggregateScore)")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(Theme.textPrimary)
                }
            }

            Divider()
                .background(Theme.surface)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(score.memberCount)")
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Members")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                VStack(spacing: 4) {
                    Text(String(format: "%.1fh", score.averageHours))
                        .font(.title3.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text("Avg Sleep")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: score.trend.icon)
                        .foregroundColor(trendColor)
                    Text(score.trend.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(trendColor)
                }
            }

            if let best = score.bestPerformer {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(Theme.warningAccent)
                        .font(.caption)
                    Text("\(best.name) had the best sleep this week")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }

    private var scoreGradient: LinearGradient {
        switch score.aggregateScore {
        case 80...100:
            return LinearGradient(colors: [Theme.insightAccent, Theme.deepSleep], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 65..<80:
            return LinearGradient(colors: [Theme.deepSleep, Theme.lightSleep], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 50..<65:
            return LinearGradient(colors: [Theme.warningAccent, Theme.heartRate], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Theme.heartRate, Theme.heartRate.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var trendColor: Color {
        switch score.trend {
        case .improving: return Theme.insightAccent
        case .stable: return Theme.textSecondary
        case .declining: return Theme.heartRate
        }
    }
}

// MARK: - Family Member Row

struct FamilyMemberRow: View {
    let member: FamilyMember
    @ObservedObject var familyService: FamilyService
    @State private var showDisconnectAlert = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.deepSleep.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: member.relationship.icon)
                    .foregroundColor(Theme.deepSleep)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(member.relationship.rawValue)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            if let score = member.sleepScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(score)")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(scoreColor(score))
                    Text("score")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Button {
                showDisconnectAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
        }
        .padding()
        .glassCard()
        .alert("Disconnect \(member.name)?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                familyService.disconnectMember(member)
            }
        } message: {
            Text("They will no longer be able to share sleep data with you.")
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return Theme.insightAccent
        case 65..<80: return Theme.deepSleep
        case 50..<65: return Theme.warningAccent
        default: return Theme.heartRate
        }
    }
}

// MARK: - Pending Member Row

struct PendingMemberRow: View {
    let member: FamilyMember
    @ObservedObject var familyService: FamilyService

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 48, height: 48)

                Image(systemName: member.relationship.icon)
                    .foregroundColor(Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("Invitation pending")
                    .font(.caption)
                    .foregroundColor(Theme.warningAccent)
            }

            Spacer()

            Button {
                familyService.removeMember(member)
            } label: {
                Text("Cancel")
                    .font(.caption.bold())
                    .foregroundColor(Theme.heartRate)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.heartRate.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Add Family Member Sheet

struct AddFamilyMemberView: View {
    @ObservedObject var familyService: FamilyService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var relationship: FamilyMember.Relationship = .partner
    @State private var inviteMethod = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.textSecondary)

                            TextField("Family member name", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(Theme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Relationship")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.textSecondary)

                            Picker("Relationship", selection: $relationship) {
                                ForEach(FamilyMember.Relationship.allCases, id: \.self) { rel in
                                    Label(rel.rawValue, systemImage: rel.icon)
                                        .tag(rel)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invite via")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.textSecondary)

                            Picker("Method", selection: $inviteMethod) {
                                Text("Share Link").tag(0)
                                Text("Direct (same device)").tag(1)
                            }
                            .pickerStyle(.segmented)
                        }

                        if inviteMethod == 1 {
                            Button {
                                // Simulate connection for demo
                                let member = FamilyMember(
                                    name: name.isEmpty ? "Partner" : name,
                                    relationship: relationship,
                                    isConnected: true,
                                    lastSyncAt: Date(),
                                    sleepScore: Int.random(in: 65...92),
                                    averageSleepHours: Double.random(in: 6.0...8.0)
                                )
                                familyService.familyMembers.append(member)
                                familyService.saveFamilyMembers()
                                dismiss()
                            } label: {
                                Text("Connect (Demo)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Theme.deepSleep, Theme.remSleep],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        } else {
                            Button {
                                // Create pending invitation
                                let member = FamilyMember(
                                    name: name.isEmpty ? "Partner" : name,
                                    relationship: relationship,
                                    isConnected: false
                                )
                                familyService.familyMembers.append(member)
                                familyService.saveFamilyMembers()
                                dismiss()
                            } label: {
                                Text("Send Invitation")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Theme.deepSleep, Theme.remSleep],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Share Family Link Sheet

struct ShareFamilyLinkView: View {
    @ObservedObject var familyService: FamilyService
    @Environment(\.dismiss) private var dismiss
    @State private var shareCode = ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.deepSleep, Theme.remSleep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 8) {
                        Text("Share with Family")
                            .font(.title2.bold())
                            .foregroundColor(Theme.textPrimary)

                        Text("Share this link with family members to compare sleep data")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    let link = familyService.generateShareLink()

                    VStack(spacing: 12) {
                        Text(link)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Theme.deepSleep)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            UIPasteboard.general.string = link
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied!" : "Copy Link")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Theme.deepSleep, Theme.remSleep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    VStack(spacing: 12) {
                        Text("Or enter a code to join")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)

                        TextField("Enter 8-character code", text: $shareCode)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(Theme.textPrimary)

                        Button {
                            familyService.joinFamily(shareCode: shareCode) { success, message in
                                if success {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Join Family")
                                .font(.headline)
                                .foregroundColor(Theme.deepSleep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.deepSleep.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Family Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Family Comparison View

struct FamilyComparisonView: View {
    @ObservedObject var familyService: FamilyService
    @Environment(\.dismiss) private var dismiss
    let records: [SleepRecord]
    @State private var selectedPeriod = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Picker("Period", selection: $selectedPeriod) {
                            Text("7 Days").tag(0)
                            Text("30 Days").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if familyService.comparisons.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 48))
                                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                                Text("No comparison data yet")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.vertical, 48)
                        } else {
                            comparisonChart
                            comparisonList
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Sleep Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Score vs Partner")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 0) {
                ForEach(familyService.comparisons.prefix(7)) { comparison in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Theme.deepSleep)
                            .frame(width: 30, height: CGFloat(comparison.yourScore) * 1.5)

                        Rectangle()
                            .fill(Theme.remSleep.opacity(0.6))
                            .frame(width: 30, height: CGFloat(comparison.theirScore) * 1.5)
                    }
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Circle().fill(Theme.deepSleep).frame(width: 8, height: 8).offset(x: -120)
                    Text("You").font(.caption).foregroundColor(Theme.textSecondary).offset(x: -100)
                    Circle().fill(Theme.remSleep.opacity(0.6)).frame(width: 8, height: 8).offset(x: -50)
                    Text(familyService.getPartner()?.name ?? "Partner").font(.caption).foregroundColor(Theme.textSecondary).offset(x: -30)
                    Spacer()
                }
                .offset(y: 90),
                alignment: .leading
            )
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }

    private var comparisonList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Comparisons")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ForEach(familyService.comparisons.prefix(7)) { comparison in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDate(comparison.date))
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.textPrimary)
                        Text("You: \(String(format: "%.1f", comparison.yourSleepHours))h | \(comparison.memberName): \(String(format: "%.1f", comparison.theirSleepHours))h")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }

                    Spacer()

                    winnerBadge(comparison)
                }
                .padding(.vertical, 8)

                if comparison.id != familyService.comparisons.prefix(7).last?.id {
                    Divider().background(Theme.surface)
                }
            }
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }

    @ViewBuilder
    private func winnerBadge(_ comparison: SleepComparison) -> some View {
        switch comparison.winner {
        case .you:
            Text("You +")
                .font(.caption.bold())
                .foregroundColor(Theme.insightAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.insightAccent.opacity(0.1))
                .clipShape(Capsule())
        case .them:
            Text("+")
                .font(.caption.bold())
                .foregroundColor(Theme.warningAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.warningAccent.opacity(0.1))
                .clipShape(Capsule())
        case .tie:
            Text("Tie")
                .font(.caption.bold())
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.surface)
                .clipShape(Capsule())
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
