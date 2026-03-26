import Foundation

// MARK: - Drift R12-R20: Sleep Coaching, Programs, Ecosystem

// MARK: R12: Sleep Coaching, Programs, Smart Alarm 2.0

struct SleepProgram: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var programType: ProgramType
    var durationWeeks: Int
    var dailyActions: [DailyAction]
    var currentWeek: Int
    var startDate: Date
    var isActive: Bool
    var progressPercent: Double
    
    enum ProgramType: String, Codable {
        case deepSleepBoost = "Deep Sleep Boost"
        case sleepOnsetInsomnia = "Sleep Onset Insomnia"
        case consistencyBuilder = "Consistency Builder"
        case earlyRiser = "Early Riser"
        case nightOwlReset = "Night Owl Reset"
    }
    
    struct DailyAction: Identifiable, Codable, Equatable {
        let id: UUID
        var text: String
        var dayNumber: Int
        var isCompleted: Bool
        
        init(id: UUID = UUID(), text: String, dayNumber: Int, isCompleted: Bool = false) {
            self.id = id
            self.text = text
            self.dayNumber = dayNumber
            self.isCompleted = isCompleted
        }
    }
    
    init(id: UUID = UUID(), name: String, programType: ProgramType, durationWeeks: Int = 4, dailyActions: [DailyAction] = [], currentWeek: Int = 1, startDate: Date = Date(), isActive: Bool = true, progressPercent: Double = 0) {
        self.id = id
        self.name = name
        self.programType = programType
        self.durationWeeks = durationWeeks
        self.dailyActions = dailyActions
        self.currentWeek = currentWeek
        self.startDate = startDate
        self.isActive = isActive
        self.progressPercent = progressPercent
    }
}

struct SmartAlarm: Identifiable, Codable, Equatable {
    let id: UUID
    var wakeTime: Date
    var wakeWindowMinutes: Int
    var isEnabled: Bool
    var useSunriseAlarm: Bool
    var sunriseDurationMinutes: Int
    var morningBriefingEnabled: Bool
    var detectSleepEnd: Bool
    
    init(id: UUID = UUID(), wakeTime: Date = Date(), wakeWindowMinutes: Int = 20, isEnabled: Bool = true, useSunriseAlarm: Bool = false, sunriseDurationMinutes: Int = 15, morningBriefingEnabled: Bool = true, detectSleepEnd: Bool = true) {
        self.id = id
        self.wakeTime = wakeTime
        self.wakeWindowMinutes = wakeWindowMinutes
        self.isEnabled = isEnabled
        self.useSunriseAlarm = useSunriseAlarm
        self.sunriseDurationMinutes = sunriseDurationMinutes
        self.morningBriefingEnabled = morningBriefingEnabled
        self.detectSleepEnd = detectSleepEnd
    }
}

struct MorningBriefing: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var sleepScore: Double
    var sleepGoalMet: Bool
    var weatherSummary: String?
    var tomorrowSleepGoal: String?
    var motivationalTip: String
    
    init(id: UUID = UUID(), date: Date = Date(), sleepScore: Double, sleepGoalMet: Bool = false, weatherSummary: String? = nil, tomorrowSleepGoal: String? = nil, motivationalTip: String = "") {
        self.id = id
        self.date = date
        self.sleepScore = sleepScore
        self.sleepGoalMet = sleepGoalMet
        self.weatherSummary = weatherSummary
        self.tomorrowSleepGoal = tomorrowSleepGoal
        self.motivationalTip = motivationalTip
    }
}

// MARK: R13: Partner Integrations, Wearable Ecosystem

struct WearableIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var deviceType: DeviceType
    var isConnected: Bool
    var lastSyncAt: Date?
    var dataTypes: [DataType]
    
    enum DeviceType: String, Codable {
        case appleWatch = "Apple Watch"
        case oura = "Oura Ring"
        case whoop = "Whoop"
        case fitbit = "Fitbit"
        case eightSleep = "Eight Sleep"
        case tempurPedic = "Tempur-Pedic Smart Bed"
        case withings = "Withings"
        case garmin = "Garmin"
    }
    
    enum DataType: String, Codable {
        case heartRate, hrv, remSleep, deepSleep, lightSleep, awakeTime, temperature, respiratoryRate, movement
    }
    
    init(id: UUID = UUID(), deviceName: String, deviceType: DeviceType, isConnected: Bool = false, lastSyncAt: Date? = nil, dataTypes: [DataType] = []) {
        self.id = id
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.isConnected = isConnected
        self.lastSyncAt = lastSyncAt
        self.dataTypes = dataTypes
    }
}

struct WearableDataSync: Identifiable, Codable {
    let id: UUID
    var wearableID: UUID
    var syncedAt: Date
    var dataQuality: Quality
    var dataPoints: [String: AnyCodable]
    
    enum Quality: String, Codable {
        case excellent, good, fair, poor
    }
    
    init(id: UUID = UUID(), wearableID: UUID, syncedAt: Date = Date(), dataQuality: Quality = .good, dataPoints: [String: AnyCodable] = [:]) {
        self.id = id
        self.wearableID = wearableID
        self.syncedAt = syncedAt
        self.dataQuality = dataQuality
        self.dataPoints = dataPoints
    }
}

// MARK: R14: Family & Couples, Multi-User Support

struct SleepRoom: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var memberIDs: [String]
    var isPaired: Bool
    var pairedDeviceID: String?
    var roomEnvironment: RoomEnvironment
    var sharedInsights: [SharedInsight]
    
    struct RoomEnvironment: Codable, Equatable {
        var temperature: Double?
        var humidity: Double?
        var noiseLevel: Double?
        var lightLevel: Double?
        var airQuality: String?
    }
    
    struct SharedInsight: Identifiable, Codable, Equatable {
        let id: UUID
        var text: String
        var createdAt: Date
        var authorID: String
    }
    
    init(id: UUID = UUID(), name: String, memberIDs: [String] = [], isPaired: Bool = false, pairedDeviceID: String? = nil, roomEnvironment: RoomEnvironment = RoomEnvironment(), sharedInsights: [SharedInsight] = []) {
        self.id = id
        self.name = name
        self.memberIDs = memberIDs
        self.isPaired = isPaired
        self.pairedDeviceID = pairedDeviceID
        self.roomEnvironment = roomEnvironment
        self.sharedInsights = sharedInsights
    }
}

// MARK: R15: Content, Sleep Music, Soundscapes

struct SleepContent: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var contentType: ContentType
    var duration: TimeInterval
    var category: Category
    var creatorName: String?
    var isPremium: Bool
    var playCount: Int
    var audioURL: URL?
    var thumbnailURL: URL?
    
    enum ContentType: String, Codable {
        case soundscape = "Soundscape"
        case music = "Music"
        case story = "Story"
        case meditation = "Meditation"
        case podcast = "Podcast"
        case audiobook = "Audiobook"
        case whiteNoise = "White Noise"
        case rainSounds = "Rain Sounds"
        case natureSounds = "Nature Sounds"
    }
    
    enum Category: String, Codable {
        case nature, ambient, music, stories, meditation, whiteNoise, rain, sleepTalk, fitness, focus
    }
    
    init(id: UUID = UUID(), title: String, contentType: ContentType, duration: TimeInterval = 0, category: Category = .ambient, creatorName: String? = nil, isPremium: Bool = false, playCount: Int = 0, audioURL: URL? = nil, thumbnailURL: URL? = nil) {
        self.id = id
        self.title = title
        self.contentType = contentType
        self.duration = duration
        self.category = category
        self.creatorName = creatorName
        self.isPremium = isPremium
        self.playCount = playCount
        self.audioURL = audioURL
        self.thumbnailURL = thumbnailURL
    }
}

struct SleepPlaylist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var contentIDs: [UUID]
    var totalDuration: TimeInterval
    var isAutoGenerated: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, contentIDs: [UUID] = [], totalDuration: TimeInterval = 0, isAutoGenerated: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.contentIDs = contentIDs
        self.totalDuration = totalDuration
        self.isAutoGenerated = isAutoGenerated
        self.createdAt = createdAt
    }
}

// MARK: R16: Subscription Business

struct DriftSubscriptionTier: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var displayName: String
    var monthlyPrice: Decimal
    var annualPrice: Decimal
    var lifetimePrice: Decimal
    var features: [String]
    var isMostPopular: Bool
    
    static let free = DriftSubscriptionTier(id: UUID(), name: "free", displayName: "Free", monthlyPrice: 0, annualPrice: 0, lifetimePrice: 0, features: ["Basic sleep tracking", "7-day history", "Simple insights"], isMostPopular: false)
    static let premium = DriftSubscriptionTier(id: UUID(), name: "premium", displayName: "Premium", monthlyPrice: 7.99, annualPrice: 79.99, lifetimePrice: 149, features: ["AI sleep programs", "Smart alarm", "Sleep music library", "Wearable sync", "Unlimited history"], isMostPopular: true)
    static let family = DriftSubscriptionTier(id: UUID(), name: "family", displayName: "Family", monthlyPrice: 11.99, annualPrice: 119.99, lifetimePrice: 0, features: ["Up to 6 members", "Room environment tracking", "Shared insights", "Priority support"], isMostPopular: false)
}

// MARK: R17: Android, Web, International

struct CrossPlatformSync: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceID: String
    var platform: Platform
    var lastSyncAt: Date
    var isPrimary: Bool
    
    enum Platform: String, Codable {
        case ios, android, web, watchOS
    }
    
    init(id: UUID = UUID(), deviceID: String, platform: Platform, lastSyncAt: Date = Date(), isPrimary: Bool = false) {
        self.id = id
        self.deviceID = deviceID
        self.platform = platform
        self.lastSyncAt = lastSyncAt
        self.isPrimary = isPrimary
    }
}

// MARK: R18: Team Building, Long-Term Architecture

struct TeamMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var email: String
    
    init(id: UUID = UUID(), name: String, role: String, email: String) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
    }
}

// MARK: R19: Awards, Press, Community

struct AwardSubmission: Identifiable, Codable, Equatable {
    let id: UUID
    var awardName: String
    var category: String
    var status: Status
    var submittedAt: Date
    
    enum Status: String, Codable {
        case draft, submitted, inReview, won, rejected
    }
    
    init(id: UUID = UUID(), awardName: String, category: String, status: Status = .draft, submittedAt: Date = Date()) {
        self.id = id
        self.awardName = awardName
        self.category = category
        self.status = status
        self.submittedAt = submittedAt
    }
}

// MARK: R20: Platform Ecosystem, Vision Pro, SDK

struct PlatformIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var platform: Platform
    var integrationType: IntegrationType
    var isEnabled: Bool
    var config: [String: String]
    
    enum Platform: String, Codable {
        case appleVisionPro = "Apple Vision Pro"
        case embeddedSDK = "Embedded SDK"
        case oura = "Oura"
        case whoop = "Whoop"
        case eightSleep = "Eight Sleep"
        case tempurPedic = "Tempur-Pedic"
    }
    
    enum IntegrationType: String, Codable {
        case nativeApp, sdk, api, certified
    }
    
    init(id: UUID = UUID(), platform: Platform, integrationType: IntegrationType, isEnabled: Bool = false, config: [String: String] = [:]) {
        self.id = id
        self.platform = platform
        self.integrationType = integrationType
        self.isEnabled = isEnabled
        self.config = config
    }
}

struct DriftAPI: Codable, Equatable {
    var clientID: String
    var clientSecret: String
    var accessToken: String?
    var tier: APITier
    
    enum APITier: String, Codable {
        case free = "Free"
        case paid = "Paid"
    }
    
    init(clientID: String = UUID().uuidString, clientSecret: String = UUID().uuidString, accessToken: String? = nil, tier: APITier = .free) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.accessToken = accessToken
        self.tier = tier
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        }
    }
}
