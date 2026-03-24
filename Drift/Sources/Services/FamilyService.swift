import Foundation
import Combine

@MainActor
class FamilyService: ObservableObject {
    @Published var familyMembers: [FamilyMember] = []
    @Published var familySleepScore: FamilySleepScore?
    @Published var comparisons: [SleepComparison] = []
    @Published var isLoading = false

    private let userDefaultsKey = "familyMembers"
    private let currentUserKey = "currentUserName"

    var currentUserName: String {
        get { UserDefaults.standard.string(forKey: currentUserKey) ?? "You" }
        set { UserDefaults.standard.set(newValue, forKey: currentUserKey) }
    }

    init() {
        loadFamilyMembers()
    }

    // MARK: - Persistence

    private func loadFamilyMembers() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let members = try? JSONDecoder().decode([FamilyMember].self, from: data) else {
            return
        }
        familyMembers = members
    }

    func saveFamilyMembers() {
        guard let data = try? JSONEncoder().encode(familyMembers) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    // MARK: - Family Member Management

    func addMember(name: String, relationship: FamilyMember.Relationship) {
        let member = FamilyMember(name: name, relationship: relationship, isConnected: false)
        familyMembers.append(member)
        saveFamilyMembers()
    }

    func removeMember(_ member: FamilyMember) {
        familyMembers.removeAll { $0.id == member.id }
        saveFamilyMembers()
    }

    func updateMember(_ member: FamilyMember) {
        if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
            familyMembers[index] = member
            saveFamilyMembers()
        }
    }

    func connectMember(_ member: FamilyMember, sleepScore: Int?, averageHours: Double?) {
        if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
            familyMembers[index].isConnected = true
            familyMembers[index].sleepScore = sleepScore
            familyMembers[index].averageSleepHours = averageHours
            familyMembers[index].lastSyncAt = Date()
            saveFamilyMembers()
        }
    }

    func disconnectMember(_ member: FamilyMember) {
        if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
            familyMembers[index].isConnected = false
            familyMembers[index].lastSyncAt = nil
            saveFamilyMembers()
        }
    }

    // MARK: - Family Sleep Score

    func calculateFamilySleepScore(records: [SleepRecord]) {
        let connectedMembers = familyMembers.filter { $0.isConnected }

        guard !connectedMembers.isEmpty else {
            // Use only current user's data
            if let avgScore = records.isEmpty ? nil : records.map({ $0.score }).reduce(0, +) / records.count,
               let avgHours = records.isEmpty ? nil : records.map({ $0.totalHours }).reduce(0, +) / Double(records.count) {
                familySleepScore = FamilySleepScore(
                    aggregateScore: avgScore,
                    memberCount: 1,
                    averageHours: avgHours,
                    bestPerformer: nil,
                    needsImprovement: [],
                    trend: .stable
                )
            }
            return
        }

        // Calculate aggregate score
        let memberScores = connectedMembers.compactMap { $0.sleepScore }
        let memberHours = connectedMembers.compactMap { $0.averageSleepHours }
        let userAvgScore = records.isEmpty ? nil : records.map({ $0.score }).reduce(0, +) / records.count
        let userAvgHours = records.isEmpty ? nil : records.map({ $0.totalHours }).reduce(0, +) / Double(records.count)

        var allScores = memberScores
        var allHours = memberHours

        if let score = userAvgScore { allScores.append(score) }
        if let hours = userAvgHours { allHours.append(hours) }

        guard !allScores.isEmpty else { return }

        let aggregateScore = allScores.reduce(0, +) / allScores.count
        let averageHours = allHours.reduce(0, +) / Double(allHours.count)

        // Find best performer
        let bestPerformer = connectedMembers.max { ($0.sleepScore ?? 0) < ($1.sleepScore ?? 0) }

        // Find who needs improvement (score below 65)
        let needsImprovement = connectedMembers.filter { ($0.sleepScore ?? 100) < 65 }

        // Calculate trend (simplified - would need historical data for real implementation)
        let trend: FamilySleepScore.Trend = aggregateScore >= 75 ? .improving :
                                           aggregateScore >= 60 ? .stable : .declining

        familySleepScore = FamilySleepScore(
            aggregateScore: aggregateScore,
            memberCount: allScores.count,
            averageHours: averageHours,
            bestPerformer: bestPerformer,
            needsImprovement: needsImprovement,
            trend: trend
        )
    }

    // MARK: - Partner Comparison

    func generateComparisons(records: [SleepRecord]) {
        let connectedMembers = familyMembers.filter { $0.isConnected && $0.relationship == .partner }
        comparisons.removeAll()

        for member in connectedMembers {
            // Generate comparisons for the past 7 days where both have data
            for record in records.prefix(7) {
                let comparison = SleepComparison(
                    memberName: member.name,
                    date: record.date,
                    yourSleepHours: record.totalHours,
                    theirSleepHours: member.averageSleepHours ?? 7.0,
                    yourScore: record.score,
                    theirScore: member.sleepScore ?? 75,
                    winner: record.score > (member.sleepScore ?? 75) ? .you :
                           record.score < (member.sleepScore ?? 75) ? .them : .tie
                )
                comparisons.append(comparison)
            }
        }
    }

    func getPartner() -> FamilyMember? {
        return familyMembers.first { $0.isConnected && $0.relationship == .partner }
    }

    // MARK: - Share Link (simulated - would use CloudKit/SharePlay in production)

    func generateShareLink() -> String {
        // In production, this would use CloudKit or a proper sharing mechanism
        // For now, generate a unique share code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let shareCode = String((0..<8).map { _ in characters.randomElement()! })
        return "drift://family/join/\(shareCode)"
    }

    func joinFamily(shareCode: String, completion: @escaping (Bool, String) -> Void) {
        // Simulate network request
        // In production, this would validate against a backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if shareCode.count == 8 {
                completion(true, "Successfully joined family group!")
            } else {
                completion(false, "Invalid share code")
            }
        }
    }
}
