import Foundation

/// Comprehensive AI-powered sleep analysis with debt tracking, window detection, and pattern analysis.
struct DeepSleepAnalysis: Codable {
    var sleepDebtMinutes: Int // compared to 8hr (480min) target
    var bestSleepWindow: String? // "11pm-7am"
    var detectedPatterns: [String] // ["consistent bedtime", "weekend oversleep"]
    var weeklyTrend: String // "improving", "declining", "stable"
    var recommendations: [String]
    var sleepStagesSummary: [SleepStageSummary]
    var snoringRisk: String? // "low", "medium", "high"
    var breathingRegularity: String? // "regular", "irregular"
    var predictedNextScore: Int? // ML-based prediction

    var sleepDebtFormatted: String {
        if sleepDebtMinutes <= 0 {
            return "On track"
        } else {
            return "\(sleepDebtMinutes) min behind"
        }
    }
}

struct SleepStageSummary: Codable {
    let stage: String // "deep", "rem", "light"
    let avgMinutes: Int
    let trend: String // "above_avg", "below_avg", "normal"
}

/// Weekly sleep trend narrative
struct WeeklySleepNarrative: Codable {
    let startDate: Date
    let endDate: Date
    let averageScore: Int
    let totalNights: Int
    let nightsWith7HoursPlus: Int
    let bestNight: Date?
    let worstNight: Date?
    let trend: String // "improving", "stable", "declining"
    let narrative: String
}
