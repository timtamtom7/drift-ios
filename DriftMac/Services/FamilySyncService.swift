import Foundation

/// Share sleep data with family members and track household sleep trends
final class FamilySyncService: ObservableObject, @unchecked Sendable {
    static let shared = FamilySyncService()

    @Published private(set) var familyMembers: [FamilyMember] = []
    @Published private(set) var lastHouseholdReport: HouseholdSleepReport?

    private let userDefaults = UserDefaults.standard
    private let familyMembersKey = "drift.family.members"

    private init() {
        loadFamilyMembers()
    }

    // MARK: - Family Members

    func addFamilyMember(name: String, relationship: FamilyRelationship) {
        let member = FamilyMember(
            id: UUID(),
            name: name,
            relationship: relationship,
            sleepHistory: [],
            joinedDate: Date()
        )
        familyMembers.append(member)
        saveFamilyMembers()
    }

    func removeFamilyMember(id: UUID) {
        familyMembers.removeAll { $0.id == id }
        saveFamilyMembers()
    }

    func updateFamilyMemberSleep(id: UUID, sleepData: HealthKitService.SleepData) {
        guard let index = familyMembers.firstIndex(where: { $0.id == id }) else { return }
        familyMembers[index].sleepHistory.insert(sleepData, at: 0)
        // Keep only last 30 nights
        if familyMembers[index].sleepHistory.count > 30 {
            familyMembers[index].sleepHistory = Array(familyMembers[index].sleepHistory.prefix(30))
        }
        saveFamilyMembers()
    }

    // MARK: - Household Report

    func generateHouseholdReport() async -> HouseholdSleepReport {
        let calendar = Calendar.current
        let today = Date()

        var memberReports: [FamilyMemberSleepReport] = []

        for member in familyMembers {
            guard let lastNight = member.sleepHistory.first else {
                memberReports.append(FamilyMemberSleepReport(
                    memberId: member.id,
                    memberName: member.name,
                    relationship: member.relationship,
                    lastNightScore: nil,
                    lastNightSleep: nil,
                    weeklyAverage: nil,
                    householdContribution: 0
                ))
                continue
            }

            let weeklyAvg = member.sleepHistory.prefix(7).map(\.totalSleep).reduce(0, +) / Double(min(7, member.sleepHistory.count))

            memberReports.append(FamilyMemberSleepReport(
                memberId: member.id,
                memberName: member.name,
                relationship: member.relationship,
                lastNightScore: lastNight.sleepScore,
                lastNightSleep: lastNight.totalSleep,
                weeklyAverage: weeklyAvg,
                householdContribution: Double(lastNight.sleepScore)
            ))
        }

        // Calculate household sleep score (average of all scores)
        let scoredMembers = memberReports.compactMap(\.lastNightScore)
        let householdScore = scoredMembers.isEmpty ? nil : scoredMembers.reduce(0, +) / scoredMembers.count

        // Determine household verdict
        let verdict = generateHouseholdVerdict(householdScore: householdScore, memberReports: memberReports)

        let report = HouseholdSleepReport(
            generatedAt: today,
            householdScore: householdScore,
            memberReports: memberReports,
            verdict: verdict
        )

        await MainActor.run {
            self.lastHouseholdReport = report
        }

        return report
    }

    // MARK: - Insights

    func householdSleepInsight() async -> String {
        let report = await generateHouseholdReport()

        guard let score = report.householdScore else {
            return "Add family members to track household sleep together."
        }

        if score >= 85 {
            return "🌟 The whole family slept great last night! Keep up the amazing rest."
        } else if score >= 70 {
            return "👍 Pretty good night for the household. A few small tweaks could push everyone higher."
        } else if score >= 50 {
            return "💤 Mixed night across the household — some might benefit from earlier bedtimes."
        } else {
            return "🌙 Tough night for the family. Consider a screen-free evening tonight."
        }
    }

    func compareMemberSleep(memberId: UUID) async -> String {
        guard let report = lastHouseholdReport,
              let member = report.memberReports.first(where: { $0.memberId == memberId }),
              let memberScore = member.lastNightScore else {
            return "No data available for comparison."
        }

        guard let householdAvg = report.householdScore else {
            return "\(member.memberName) slept \(member.lastNightSleep?.formatted ?? "—") with a score of \(memberScore)."
        }

        let diff = memberScore - householdAvg
        if diff > 10 {
            return "⭐ \(member.memberName) out-slept the household average by \(diff) points last night!"
        } else if diff < -10 {
            return "💤 \(member.memberName) had a rougher night — \(abs(diff)) points below household average."
        } else {
            return "⚖️ \(member.memberName) was right in line with the household average."
        }
    }

    // MARK: - Private Helpers

    private func generateHouseholdVerdict(householdScore: Int?, memberReports: [FamilyMemberSleepReport]) -> String {
        guard let score = householdScore else {
            return "Track more sleep data to get household insights."
        }

        if score >= 90 {
            return "🏆 Household sleep champions! Everyone's thriving."
        } else if score >= 80 {
            return "🌟 Excellent household sleep — the family is well-rested."
        } else if score >= 70 {
            return "👍 Good household sleep overall."
        } else if score >= 60 {
            return "💤 Decent rest, but there's room to improve."
        } else if score >= 40 {
            return "🌙 The household could use some better sleep habits."
        } else {
            return "😴 Rough night for everyone. Time for a sleep reset."
        }
    }

    private func loadFamilyMembers() {
        guard let data = userDefaults.data(forKey: familyMembersKey),
              let members = try? JSONDecoder().decode([CodableFamilyMember].self, from: data) else {
            return
        }
        familyMembers = members.map { $0.toFamilyMember() }
    }

    private func saveFamilyMembers() {
        let codable = familyMembers.map { CodableFamilyMember(from: $0) }
        if let data = try? JSONEncoder().encode(codable) {
            userDefaults.set(data, forKey: familyMembersKey)
        }
    }
}

// MARK: - Data Models

extension FamilySyncService {
    struct FamilyMember: Identifiable {
        let id: UUID
        var name: String
        var relationship: FamilyRelationship
        var sleepHistory: [HealthKitService.SleepData]
        let joinedDate: Date
    }

    enum FamilyRelationship: String, Codable, CaseIterable {
        case partner = "Partner"
        case child = "Child"
        case parent = "Parent"
        case sibling = "Sibling"
        case roommate = "Roommate"
        case other = "Other"
    }

    struct HouseholdSleepReport: Sendable {
        let generatedAt: Date
        let householdScore: Int?
        let memberReports: [FamilyMemberSleepReport]
        let verdict: String

        var summaryText: String {
            guard let score = householdScore else {
                return "Not enough data yet."
            }
            return "Household Sleep Score: \(score)/100"
        }
    }

    struct FamilyMemberSleepReport: Sendable {
        let memberId: UUID
        let memberName: String
        let relationship: FamilyRelationship
        let lastNightScore: Int?
        let lastNightSleep: TimeInterval?
        let weeklyAverage: TimeInterval?
        let householdContribution: Double

        var lastNightSleepFormatted: String {
            guard let sleep = lastNightSleep else { return "No data" }
            let hours = Int(sleep) / 3600
            let minutes = (Int(sleep) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

        var weeklyAverageFormatted: String {
            guard let avg = weeklyAverage else { return "—" }
            let hours = Int(avg) / 3600
            let minutes = (Int(avg) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Codable Bridge

private struct CodableSleepData: Codable {
    let totalSleep: TimeInterval
    let deepSleep: TimeInterval
    let remSleep: TimeInterval
    let awake: TimeInterval
    let sleepScore: Int

    init(from data: HealthKitService.SleepData) {
        self.totalSleep = data.totalSleep
        self.deepSleep = data.deepSleep
        self.remSleep = data.remSleep
        self.awake = data.awake
        self.sleepScore = data.sleepScore
    }

    func toSleepData() -> HealthKitService.SleepData {
        HealthKitService.SleepData(
            totalSleep: totalSleep,
            deepSleep: deepSleep,
            remSleep: remSleep,
            awake: awake,
            sleepScore: sleepScore
        )
    }
}

private struct CodableFamilyMember: Codable {
    let id: UUID
    var name: String
    var relationshipRaw: String
    var sleepHistory: [CodableSleepData]
    let joinedDate: Date

    init(from member: FamilySyncService.FamilyMember) {
        self.id = member.id
        self.name = member.name
        self.relationshipRaw = member.relationship.rawValue
        self.sleepHistory = member.sleepHistory.map { CodableSleepData(from: $0) }
        self.joinedDate = member.joinedDate
    }

    func toFamilyMember() -> FamilySyncService.FamilyMember {
        let relationship = FamilySyncService.FamilyRelationship(rawValue: relationshipRaw) ?? .other
        let history = sleepHistory.map { $0.toSleepData() }
        return FamilySyncService.FamilyMember(
            id: id,
            name: name,
            relationship: relationship,
            sleepHistory: history,
            joinedDate: joinedDate
        )
    }
}

// MARK: - TimeInterval Extension

private extension TimeInterval {
    var formatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
