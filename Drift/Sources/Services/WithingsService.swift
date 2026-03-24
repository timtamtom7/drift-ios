import Foundation

/// Withings Integration Service
/// Fetches body metrics (weight, body composition) from Withings via OAuth2.
/// Docs: https://developer.withings.com/
@MainActor
class WithingsService: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastSyncDate: Date?
    @Published var userId: String?

    private let userDefaultsTokenKey = "withings_access_token"
    private let userDefaultsSecretKey = "withings_access_secret"
    private let userDefaultsUserKey = "withings_user_id"
    private let baseURL = "https://wbsapi.withings.net"

    /// OAuth 2.0 client credentials (configured in Withings Developer Portal)
    /// Users authorize via OAuth flow - for demo purposes we use a placeholder
    /// In production, implement OAuth 2.0 Authorization Code flow
    private let clientId = "YOUR_WITHINGS_CLIENT_ID"
    private let clientSecret = "YOUR_WITHINGS_CLIENT_SECRET"
    private let redirectURI = "drift://withings/callback"

    var accessToken: String? {
        UserDefaults.standard.string(forKey: userDefaultsTokenKey)
    }

    var isAuthorized: Bool {
        accessToken != nil && isConnected
    }

    /// Initiate OAuth flow - returns the authorization URL
    /// In a real app, open this URL in a Safari view and handle the callback
    func authorizationURL() -> URL? {
        let state = UUID().uuidString
        UserDefaults.standard.set(state, forKey: "withings_oauth_state")

        var components = URLComponents(string: "https://account.withings.com/oauth2_user/authorize2")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "user.metrics"),
            URLQueryItem(name: "state", value: state)
        ]
        return components?.url
    }

    /// Exchange authorization code for access token
    /// Called from the OAuth callback URL handler
    func handleOAuthCallback(code: String, state: String) async -> Bool {
        guard state == UserDefaults.standard.string(forKey: "withings_oauth_state") else {
            error = "Invalid OAuth state. Please try again."
            return false
        }

        guard let url = URL(string: "https://wbsapi.withings.net/v2/oauth2") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "action": "requesttoken",
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                error = "Token exchange failed."
                return false
            }

            let result = try JSONDecoder().decode(WithingsTokenResponse.self, from: data)

            UserDefaults.standard.set(result.accessToken, forKey: userDefaultsTokenKey)
            UserDefaults.standard.set(result.refreshToken, forKey: userDefaultsSecretKey)
            UserDefaults.standard.set(String(result.userId), forKey: userDefaultsUserKey)

            userId = String(result.userId)
            isConnected = true
            lastSyncDate = Date()
            return true
        } catch {
            self.error = "Failed to connect to Withings: \(error.localizedDescription)"
            return false
        }
    }

    /// Disconnect Withings integration
    func disconnect() {
        UserDefaults.standard.removeObject(forKey: userDefaultsTokenKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsSecretKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsUserKey)
        isConnected = false
        lastSyncDate = nil
        userId = nil
    }

    /// Fetch weight and body composition data
    func fetchMeasurements(from startDate: Date, to endDate: Date) async throws -> [WithingsMeasurement] {
        guard let token = accessToken else {
            throw WithingsError.notConnected
        }

        let startEpoch = Int(startDate.timeIntervalSince1970)
        let endEpoch = Int(endDate.timeIntervalSince1970)

        var components = URLComponents(string: "\(baseURL)/measure")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "getmeas"),
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "startdate", value: String(startEpoch)),
            URLQueryItem(name: "enddate", value: String(endEpoch)),
            URLQueryItem(name: "meastype", value: "1,6,8,9,10,11,12")  // weight, fat-free mass, fat ratio, fat mass, diastolic, systolic, heart pulse
        ]

        guard let url = components?.url else {
            throw WithingsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WithingsError.networkError
        }

        if httpResponse.statusCode == 401 {
            isConnected = false
            throw WithingsError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw WithingsError.apiError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(WithingsMeasureResponse.self, from: data)
        lastSyncDate = Date()
        return result.records
    }

    /// Fetch activity data (steps, distance) if available
    func fetchActivity(from startDate: Date, to endDate: Date) async throws -> [WithingsActivity] {
        guard let token = accessToken else {
            throw WithingsError.notConnected
        }

        let startEpoch = Int(startDate.timeIntervalSince1970)
        let endEpoch = Int(endDate.timeIntervalSince1970)

        var components = URLComponents(string: "\(baseURL)/v2/measure")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "getactivity"),
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "startdateymd", value: ISO8601DateFormatter().string(from: startDate)),
            URLQueryItem(name: "enddateymd", value: ISO8601DateFormatter().string(from: endDate))
        ]

        guard let url = components?.url else {
            throw WithingsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WithingsError.networkError
        }

        let result = try JSONDecoder().decode(WithingsActivityResponse.self, from: data)
        return result.activities
    }
}

// MARK: - Models

struct WithingsTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "userid"
    }
}

struct WithingsMeasureResponse: Decodable {
    let records: [WithingsMeasurement]
}

struct WithingsMeasurement: Identifiable, Decodable {
    let id: UUID
    let date: Date
    let weightKg: Double?          // kg
    let fatFreeMassKg: Double?      // kg
    let fatRatioPercent: Double?    // %
    let fatMassKg: Double?          // kg
    let diastolicMmhg: Double?       // mmHg
    let systolicMmhg: Double?       // mmHg
    let heartRateBpm: Int?          // bpm

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Withings uses a list of measurements with type codes
        let measures = try container.decode([WithingsMeasureValue].self, forKey: .measures)
        let dateStr = try container.decode(String.self, forKey: .date)

        self.id = UUID()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.date(from: dateStr) ?? Date()

        var weight: Double?
        var fatFree: Double?
        var fatRatio: Double?
        var fatMass: Double?
        var diastolic: Double?
        var systolic: Double?
        var heartRate: Int?

        for measure in measures {
            switch measure.type {
            case 1: weight = measure.value
            case 6: fatFree = measure.value
            case 9: fatRatio = measure.value
            case 10: fatMass = measure.value
            case 11: diastolic = measure.value
            case 12: systolic = measure.value
            case 8: heartRate = Int(measure.value)
            default: break
            }
        }

        self.weightKg = weight
        self.fatFreeMassKg = fatFree
        self.fatRatioPercent = fatRatio
        self.fatMassKg = fatMass
        self.diastolicMmhg = diastolic
        self.systolicMmhg = systolic
        self.heartRateBpm = heartRate
    }

    var weightLbs: Double? {
        guard let kg = weightKg else { return nil }
        return kg * 2.20462
    }

    enum CodingKeys: String, CodingKey {
        case date
        case measures
    }
}

struct WithingsMeasureValue: Decodable {
    let type: Int       // 1=weight, 6=fat free, 9=fat ratio, 10=fat mass, 11=diastolic, 12=systolic, 8=heart rate
    let value: Double
}

struct WithingsActivityResponse: Decodable {
    let activities: [WithingsActivity]
}

struct WithingsActivity: Identifiable, Decodable {
    let id: UUID
    let date: Date
    let steps: Int?
    let distanceMeters: Int?
    let caloriesBurned: Double?
    let activeSeconds: Int?

    var distanceKm: Double? {
        guard let m = distanceMeters else { return nil }
        return Double(m) / 1000.0
    }
}

// MARK: - Errors

enum WithingsError: LocalizedError {
    case notConnected
    case invalidURL
    case unauthorized
    case networkError
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Withings is not connected. Please connect in Settings."
        case .invalidURL:
            return "Invalid Withings API URL."
        case .unauthorized:
            return "Withings authorization failed. Please reconnect."
        case .networkError:
            return "Network error connecting to Withings."
        case .apiError(let statusCode):
            return "Withings API error (code: \(statusCode))."
        }
    }
}
