import Foundation
import Combine

/// Drift R12-R20 Service — Sleep Coaching, Ecosystem, Platform
final class DriftR12R20Service: ObservableObject, @unchecked Sendable {
    static let shared = DriftR12R20Service()
    
    // R12
    @Published var sleepPrograms: [SleepProgram] = []
    @Published var smartAlarms: [SmartAlarm] = []
    @Published var morningBriefings: [MorningBriefing] = []
    
    // R13
    @Published var wearableIntegrations: [WearableIntegration] = []
    @Published var wearableDataSyncs: [WearableDataSync] = []
    
    // R14
    @Published var sleepRooms: [SleepRoom] = []
    
    // R15
    @Published var sleepContent: [SleepContent] = []
    @Published var sleepPlaylists: [SleepPlaylist] = []
    
    // R16
    @Published var currentTier: DriftSubscriptionTier = .free
    
    // R17
    @Published var crossPlatformSyncs: [CrossPlatformSync] = []
    
    // R18
    @Published var teamMembers: [TeamMember] = []
    
    // R19
    @Published var awardSubmissions: [AwardSubmission] = []
    
    // R20
    @Published var platformIntegrations: [PlatformIntegration] = []
    @Published var apiCredentials: DriftAPI?
    
    private let userDefaults = UserDefaults.standard
    
    private init() { loadFromDisk() }
    
    // MARK: - R12: Sleep Programs
    
    func createSleepProgram(type: SleepProgram.ProgramType, name: String) -> SleepProgram {
        var dailyActions: [SleepProgram.DailyAction] = []
        for day in 1...28 {
            let actions = [
                "Go to bed 15 minutes earlier",
                "Avoid screens for 30 min before bed",
                "Try a 10-min wind-down routine",
                "Keep room temperature at 65°F",
                "Avoid caffeine after 2 PM",
                "Exercise today (but not within 3 hours of bed)",
                "Limit liquid intake 2 hours before bed",
                "Practice 5 minutes of deep breathing"
            ]
            let action = SleepProgram.DailyAction(text: actions.randomElement() ?? "Sleep well", dayNumber: day)
            dailyActions.append(action)
        }
        
        let program = SleepProgram(name: name, programType: type, durationWeeks: 4, dailyActions: dailyActions)
        sleepPrograms.append(program)
        saveToDisk()
        return program
    }
    
    func completeDailyAction(programID: UUID, actionID: UUID) {
        guard let pIndex = sleepPrograms.firstIndex(where: { $0.id == programID }),
              let aIndex = sleepPrograms[pIndex].dailyActions.firstIndex(where: { $0.id == actionID }) else { return }
        sleepPrograms[pIndex].dailyActions[aIndex].isCompleted = true
        updateProgramProgress(programID)
        saveToDisk()
    }
    
    private func updateProgramProgress(_ programID: UUID) {
        guard let index = sleepPrograms.firstIndex(where: { $0.id == programID }) else { return }
        let total = sleepPrograms[index].dailyActions.count
        let completed = sleepPrograms[index].dailyActions.filter { $0.isCompleted }.count
        sleepPrograms[index].progressPercent = total > 0 ? Double(completed) / Double(total) * 100 : 0
    }
    
    func createSmartAlarm(wakeTime: Date, windowMinutes: Int = 20) -> SmartAlarm {
        let alarm = SmartAlarm(wakeTime: wakeTime, wakeWindowMinutes: windowMinutes)
        smartAlarms.append(alarm)
        saveToDisk()
        return alarm
    }
    
    func generateMorningBriefing(sleepScore: Double, weatherSummary: String?) -> MorningBriefing {
        let briefing = MorningBriefing(sleepScore: sleepScore, sleepGoalMet: sleepScore >= 80, weatherSummary: weatherSummary, tomorrowSleepGoal: sleepScore >= 80 ? "Maintain your 8-hour goal" : "Focus on wind-down routine", motivationalTip: ["Rest is productive", "Quality over quantity", "Consistency is key"].randomElement() ?? "Sleep well")
        morningBriefings.append(briefing)
        saveToDisk()
        return briefing
    }
    
    // MARK: - R13: Wearable Integration
    
    func connectWearable(name: String, type: WearableIntegration.DeviceType, dataTypes: [WearableIntegration.DataType]) -> WearableIntegration {
        let wearable = WearableIntegration(deviceName: name, deviceType: type, isConnected: true, lastSyncAt: Date(), dataTypes: dataTypes)
        wearableIntegrations.append(wearable)
        saveToDisk()
        return wearable
    }
    
    func syncWearableData(_ wearableID: UUID) async {
        let sync = WearableDataSync(wearableID: wearableID, dataQuality: .good)
        await MainActor.run {
            wearableDataSyncs.append(sync)
            if let index = wearableIntegrations.firstIndex(where: { $0.id == wearableID }) {
                wearableIntegrations[index].lastSyncAt = Date()
            }
            saveToDisk()
        }
    }
    
    // MARK: - R14: Sleep Rooms
    
    func createSleepRoom(name: String, memberIDs: [String]) -> SleepRoom {
        let room = SleepRoom(name: name, memberIDs: memberIDs)
        sleepRooms.append(room)
        saveToDisk()
        return room
    }
    
    func addSharedInsight(roomID: UUID, text: String, authorID: String) {
        guard let index = sleepRooms.firstIndex(where: { $0.id == roomID }) else { return }
        let insight = SleepRoom.SharedInsight(id: UUID(), text: text, createdAt: Date(), authorID: authorID)
        sleepRooms[index].sharedInsights.append(insight)
        saveToDisk()
    }
    
    // MARK: - R15: Sleep Content
    
    func createSleepContent(title: String, type: SleepContent.ContentType, category: SleepContent.Category, duration: TimeInterval, isPremium: Bool = false) -> SleepContent {
        let content = SleepContent(title: title, contentType: type, duration: duration, category: category, isPremium: isPremium)
        sleepContent.append(content)
        saveToDisk()
        return content
    }
    
    func createPlaylist(name: String, contentIDs: [UUID]) -> SleepPlaylist {
        let totalDuration = contentIDs.compactMap { id in sleepContent.first { $0.id == id }?.duration }.reduce(0, +)
        let playlist = SleepPlaylist(name: name, contentIDs: contentIDs, totalDuration: totalDuration)
        sleepPlaylists.append(playlist)
        saveToDisk()
        return playlist
    }
    
    // MARK: - R16: Subscription
    
    func subscribe(to tier: DriftSubscriptionTier) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            currentTier = tier
            saveToDisk()
        }
        return true
    }
    
    // MARK: - R17: Cross-Platform
    
    func registerDevice(deviceID: String, platform: CrossPlatformSync.Platform) -> CrossPlatformSync {
        let sync = CrossPlatformSync(deviceID: deviceID, platform: platform)
        crossPlatformSyncs.append(sync)
        saveToDisk()
        return sync
    }
    
    // MARK: - R20: Platform Ecosystem
    
    func registerAPI(tier: DriftAPI.APITier) -> DriftAPI {
        let api = DriftAPI(tier: tier)
        apiCredentials = api
        saveToDisk()
        return api
    }
    
    func enablePlatformIntegration(platform: PlatformIntegration.Platform, integrationType: PlatformIntegration.IntegrationType) -> PlatformIntegration {
        let integration = PlatformIntegration(platform: platform, integrationType: integrationType, isEnabled: true)
        platformIntegrations.append(integration)
        saveToDisk()
        return integration
    }
    
    func submitAward(name: String, category: String) -> AwardSubmission {
        let award = AwardSubmission(awardName: name, category: category)
        awardSubmissions.append(award)
        saveToDisk()
        return award
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(sleepPrograms) { userDefaults.set(data, forKey: "drift_programs") }
        if let data = try? encoder.encode(smartAlarms) { userDefaults.set(data, forKey: "drift_alarms") }
        if let data = try? encoder.encode(morningBriefings) { userDefaults.set(data, forKey: "drift_briefings") }
        if let data = try? encoder.encode(wearableIntegrations) { userDefaults.set(data, forKey: "drift_wearables") }
        if let data = try? encoder.encode(wearableDataSyncs) { userDefaults.set(data, forKey: "drift_syncs") }
        if let data = try? encoder.encode(sleepRooms) { userDefaults.set(data, forKey: "drift_rooms") }
        if let data = try? encoder.encode(sleepContent) { userDefaults.set(data, forKey: "drift_content") }
        if let data = try? encoder.encode(sleepPlaylists) { userDefaults.set(data, forKey: "drift_playlists") }
        if let data = try? encoder.encode(crossPlatformSyncs) { userDefaults.set(data, forKey: "drift_platform_syncs") }
        if let data = try? encoder.encode(teamMembers) { userDefaults.set(data, forKey: "drift_team") }
        if let data = try? encoder.encode(awardSubmissions) { userDefaults.set(data, forKey: "drift_awards") }
        if let data = try? encoder.encode(platformIntegrations) { userDefaults.set(data, forKey: "drift_platform_integrations") }
    }
    
    private func loadFromDisk() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "drift_programs"),
           let decoded = try? decoder.decode([SleepProgram].self, from: data) { sleepPrograms = decoded }
        if let data = userDefaults.data(forKey: "drift_alarms"),
           let decoded = try? decoder.decode([SmartAlarm].self, from: data) { smartAlarms = decoded }
        if let data = userDefaults.data(forKey: "drift_briefings"),
           let decoded = try? decoder.decode([MorningBriefing].self, from: data) { morningBriefings = decoded }
        if let data = userDefaults.data(forKey: "drift_wearables"),
           let decoded = try? decoder.decode([WearableIntegration].self, from: data) { wearableIntegrations = decoded }
        if let data = userDefaults.data(forKey: "drift_syncs"),
           let decoded = try? decoder.decode([WearableDataSync].self, from: data) { wearableDataSyncs = decoded }
        if let data = userDefaults.data(forKey: "drift_rooms"),
           let decoded = try? decoder.decode([SleepRoom].self, from: data) { sleepRooms = decoded }
        if let data = userDefaults.data(forKey: "drift_content"),
           let decoded = try? decoder.decode([SleepContent].self, from: data) { sleepContent = decoded }
        if let data = userDefaults.data(forKey: "drift_playlists"),
           let decoded = try? decoder.decode([SleepPlaylist].self, from: data) { sleepPlaylists = decoded }
        if let data = userDefaults.data(forKey: "drift_platform_syncs"),
           let decoded = try? decoder.decode([CrossPlatformSync].self, from: data) { crossPlatformSyncs = decoded }
        if let data = userDefaults.data(forKey: "drift_team"),
           let decoded = try? decoder.decode([TeamMember].self, from: data) { teamMembers = decoded }
        if let data = userDefaults.data(forKey: "drift_awards"),
           let decoded = try? decoder.decode([AwardSubmission].self, from: data) { awardSubmissions = decoded }
        if let data = userDefaults.data(forKey: "drift_platform_integrations"),
           let decoded = try? decoder.decode([PlatformIntegration].self, from: data) { platformIntegrations = decoded }
    }
}
