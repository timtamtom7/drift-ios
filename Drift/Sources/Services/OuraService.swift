import Foundation

/// Oura Ring Integration Service
/// Fetches sleep, readiness, and activity data from the Oura Ring via the Oura Cloud API.
/// Docs: https://cloud.ouraring.com/docs
@MainActor
class OuraService: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastSyncDate: Date?

    private let userDefaultsKey = "oura_access_token"
    private let baseURL = "https://api.ouraring.com/v2"

    /// Returns the stored access token, if any
    var accessToken: String? {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }

    /// Check if Oura is connected
    var hasAccessToken: Bool {
        accessToken != nil && isConnected
    }

    /// Connect with an Oura Personal Access Token
    /// Users get this from: https://cloud.ouraring.com/personal-access-token
    func connect(with token: String) async -> Bool {
        UserDefaults.standard.set(token, forKey: userDefaultsKey)

        // Verify token by fetching account info
        do {
            let _ = try await fetchAccountInfo()
            isConnected = true
            lastSyncDate = Date()
            return true
        } catch {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            isConnected = false
            self.error = "Invalid Oura token. Please check and try again."
            return false
        }
    }

    /// Disconnect Oura integration
    func disconnect() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        isConnected = false
        lastSyncDate = nil
    }

    /// Fetch sleep data from Oura for a date range
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [OuraSleepRecord] {
        guard let token = accessToken else {
            throw OuraError.notConnected
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)

        guard let url = URL(string: "\(baseURL)/usercollection/sleep?start_date=\(startStr)&end_date=\(endStr)") else {
            throw OuraError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OuraError.networkError
        }

        if httpResponse.statusCode == 401 {
            isConnected = false
            throw OuraError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw OuraError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(OuraSleepResponse.self, from: data)
        lastSyncDate = Date()
        return result.data
    }

    /// Fetch readiness data (Oura's daily recovery score)
    func fetchReadinessData(from startDate: Date, to endDate: Date) async throws -> [OuraReadinessRecord] {
        guard let token = accessToken else {
            throw OuraError.notConnected
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)

        guard let url = URL(string: "\(baseURL)/usercollection/readiness?start_date=\(startStr)&end_date=\(endStr)") else {
            throw OuraError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OuraError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(OuraReadinessResponse.self, from: data)
        return result.data
    }

    /// Fetch activity data (steps, calories, etc.)
    func fetchActivityData(from startDate: Date, to endDate: Date) async throws -> [OuraActivityRecord] {
        guard let token = accessToken else {
            throw OuraError.notConnected
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)

        guard let url = URL(string: "\(baseURL)/usercollection/activity?start_date=\(startStr)&end_date=\(endStr)") else {
            throw OuraError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OuraError.networkError
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(OuraActivityResponse.self, from: data)
        return result.data
    }

    private func fetchAccountInfo() async throws -> OuraAccountInfo {
        guard let token = accessToken else {
            throw OuraError.notConnected
        }

        guard let url = URL(string: "\(baseURL)/user") else {
            throw OuraError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OuraError.networkError
        }

        let decoder = JSONDecoder()
        return try decoder.decode(OuraAccountInfo.self, from: data)
    }
}

// MARK: - API Models

struct OuraSleepResponse: Decodable {
    let data: [OuraSleepRecord]
}

struct OuraSleepRecord: Identifiable, Decodable {
    let id: String
    let calendarDate: String
    let sleepPhaseCount: Int?
    let sleepStartTimestamp: Date?
    let sleepEndTimestamp: Date?
    let totalSleepDuration: Int?        // seconds
    let totalBedtime: Int?              // seconds
    let awakeTime: Int?                  // seconds
    let lightSleepDuration: Int?         // seconds
    let deepSleepDuration: Int?         // seconds
    let remSleepDuration: Int?          // seconds
    let sleepScore: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case calendarDate = "calendar_date"
        case sleepPhaseCount = "sleep_phase_count"
        case sleepStartTimestamp = "sleep_start_timestamp"
        case sleepEndTimestamp = "sleep_end_timestamp"
        case totalSleepDuration = "total_sleep_duration"
        case totalBedtime = "total_bedtime"
        case awakeTime = "awake_time"
        case lightSleepDuration = "light_sleep_duration"
        case deepSleepDuration = "deep_sleep_duration"
        case remSleepDuration = "rem_sleep_duration"
        case sleepScore = "sleep_score"
    }

    var deepSleepMinutes: Int {
        (deepSleepDuration ?? 0) / 60
    }

    var remSleepMinutes: Int {
        (remSleepDuration ?? 0) / 60
    }

    var lightSleepMinutes: Int {
        (lightSleepDuration ?? 0) / 60
    }

    var awakeMinutes: Int {
        (awakeTime ?? 0) / 60
    }

    var totalHours: Double {
        Double(totalSleepDuration ?? 0) / 3600.0
    }
}

struct OuraReadinessResponse: Decodable {
    let data: [OuraReadinessRecord]
}

struct OuraReadinessRecord: Identifiable, Decodable {
    let id: String
    let calendarDate: String
    let readinessScore: Int?
    let contributors: OuraReadinessContributors?

    enum CodingKeys: String, CodingKey {
        case id
        case calendarDate = "calendar_date"
        case readinessScore = "readiness_score"
        case contributors
    }
}

struct OuraReadinessContributors: Decodable {
    let sleep: Double?
    let previousDayActivity: Double?
    let previousNight: Double?
    let restingHeartRate: Double?
    let hrvBalance: Double?

    enum CodingKeys: String, CodingKey {
        case sleep
        case previousDayActivity = "previous_day_activity"
        case previousNight = "previous_night"
        case restingHeartRate = "resting_heart_rate"
        case hrvBalance = "hrv_balance"
    }
}

struct OuraActivityResponse: Decodable {
    let data: [OuraActivityRecord]
}

struct OuraActivityRecord: Identifiable, Decodable {
    let id: String
    let calendarDate: String
    let steps: Int?
    let totalCalorieBurn: Double?
    let activeCalorieBurn: Double?
    let equivalentWalkingDistance: Int?  // meters

    enum CodingKeys: String, CodingKey {
        case id
        case calendarDate = "calendar_date"
        case steps
        case totalCalorieBurn = "total_calorie_burn"
        case activeCalorieBurn = "active_calorie_burn"
        case equivalentWalkingDistance = "equivalent_walking_distance"
    }
}

struct OuraAccountInfo: Decodable {
    let email: String?
    let memberId: String?

    enum CodingKeys: String, CodingKey {
        case email
        case memberId = "member_id"
    }
}

// MARK: - Errors

enum OuraError: LocalizedError {
    case notConnected
    case invalidURL
    case unauthorized
    case networkError
    case apiError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Oura Ring is not connected. Please connect in Settings."
        case .invalidURL:
            return "Invalid Oura API URL."
        case .unauthorized:
            return "Oura authorization failed. Please reconnect."
        case .networkError:
            return "Network error connecting to Oura."
        case .apiError(let statusCode):
            return "Oura API error (code: \(statusCode))."
        case .decodingError:
            return "Failed to parse Oura data."
        }
    }
}
