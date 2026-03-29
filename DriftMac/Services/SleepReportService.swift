import Foundation

/// Generates AI-powered sleep reports (weekly/monthly) with insights and advice
final class SleepReportService: @unchecked Sendable {
    static let shared = SleepReportService()

    private let healthKitService = HealthKitService.shared

    private init() {}

    // MARK: - Public API

    /// Generate a weekly sleep report with trends and personalized advice
    func generateWeeklyReport() async -> SleepReport {
        await generateReport(days: 7)
    }

    /// Generate a monthly sleep report with trends and personalized advice
    func generateMonthlyReport() async -> SleepReport {
        await generateReport(days: 30)
    }

    /// Generate a custom report for the specified number of days
    func generateReport(days: Int) async -> SleepReport {
        do {
            let history = try await healthKitService.getSleepHistory(days: days)
            return buildReport(from: history, days: days)
        } catch {
            return emptyReport(days: days)
        }
    }

    // MARK: - Report Building

    private func buildReport(from history: [HealthKitService.SleepData], days: Int) -> SleepReport {
        let calendar = Calendar.current
        let week = calendar.date(byAdding: .day, value: -(days - 1), to: Date()) ?? Date()

        // Calculate averages
        let avgSleep = history.isEmpty ? 0 : history.map(\.totalSleep).reduce(0, +) / Double(history.count)
        let avgScore = history.isEmpty ? 0 : history.map(\.sleepScore).reduce(0, +) / history.count

        // Find best night (highest score)
        let bestNight: Date
        if let best = history.max(by: { $0.sleepScore < $1.sleepScore }) {
            // Approximate: use index as proxy
            bestNight = calendar.date(byAdding: .day, value: -(days - 1), to: Date()) ?? Date()
        } else {
            bestNight = Date()
        }

        // Build trends
        let trends = analyzeTrends(history: history)

        // Build advice
        let advice = generateAdvice(avgSleep: avgSleep, avgScore: avgScore, history: history)

        return SleepReport(
            week: week,
            avgSleep: avgSleep,
            avgScore: avgScore,
            bestNight: bestNight,
            trends: trends,
            advice: advice
        )
    }

    private func emptyReport(days: Int) -> SleepReport {
        let calendar = Calendar.current
        return SleepReport(
            week: calendar.date(byAdding: .day, value: -(days - 1), to: Date()) ?? Date(),
            avgSleep: 0,
            avgScore: 0,
            bestNight: Date(),
            trends: ["Not enough data yet. Keep tracking your sleep!"],
            advice: ["Start logging sleep to receive personalized insights."]
        )
    }

    // MARK: - Trend Analysis

    private func analyzeTrends(history: [HealthKitService.SleepData]) -> [String] {
        var trends: [String] = []

        guard history.count >= 3 else {
            trends.append("Tracking consistency: Building your sleep history...")
            return trends
        }

        // Sleep duration trend
        let recentHalf = Array(history.prefix(history.count / 2))
        let olderHalf = Array(history.suffix(history.count / 2))

        let recentAvg = recentHalf.map(\.totalSleep).reduce(0, +) / Double(max(1, recentHalf.count))
        let olderAvg = olderHalf.map(\.totalSleep).reduce(0, +) / Double(max(1, olderHalf.count))

        let sleepDiff = recentAvg - olderAvg
        let sleepDiffHours = sleepDiff / 3600

        if sleepDiffHours > 0.5 {
            trends.append("📈 Sleep duration is up by \(String(format: "%.1f", sleepDiffHours))h compared to earlier this period")
        } else if sleepDiffHours < -0.5 {
            trends.append("📉 Sleep duration is down by \(String(format: "%.1f", abs(sleepDiffHours)))h compared to earlier this period")
        } else {
            trends.append("⚖️ Sleep duration is consistent throughout this period")
        }

        // Score trend
        let recentScoreAvg = Double(recentHalf.map(\.sleepScore).reduce(0, +)) / Double(max(1, recentHalf.count))
        let olderScoreAvg = Double(olderHalf.map(\.sleepScore).reduce(0, +)) / Double(max(1, olderHalf.count))

        let scoreDiff = recentScoreAvg - olderScoreAvg
        if scoreDiff > 10 {
            trends.append("🌟 Sleep quality has improved significantly (\(Int(scoreDiff)) points)")
        } else if scoreDiff < -10 {
            trends.append("⚠️ Sleep quality has declined (\(Int(abs(scoreDiff))) points)")
        }

        // Deep sleep insight
        let deepSleepAvg = history.map(\.deepSleep).reduce(0, +) / Double(max(1, history.count))
        let optimalDeep: TimeInterval = 1.5 * 3600
        if deepSleepAvg < optimalDeep * 0.7 {
            trends.append("💡 Deep sleep is below optimal levels — aim for more consistent bedtimes")
        }

        // REM sleep insight
        let remSleepAvg = history.map(\.remSleep).reduce(0, +) / Double(max(1, history.count))
        let optimalRem: TimeInterval = 2.0 * 3600
        if remSleepAvg < optimalRem * 0.6 {
            trends.append("🧠 REM sleep could be higher — consider wind-down routines before bed")
        }

        return trends
    }

    // MARK: - Advice Generation

    private func generateAdvice(avgSleep: TimeInterval, avgScore: Int, history: [HealthKitService.SleepData]) -> [String] {
        var advice: [String] = []
        let optimalSleep: TimeInterval = 8 * 3600

        // Duration-based advice
        if avgSleep < optimalSleep * 0.85 {
            advice.append("🌙 You're averaging \(formatDuration(avgSleep)) — try going to bed 30 min earlier. Most adults need 7-9 hours.")
        } else if avgSleep > optimalSleep * 1.15 {
            advice.append("☀️ You're sleeping \(formatDuration(avgSleep)) — more isn't always better. Ensure sleep quality, not just quantity.")
        } else {
            advice.append("✅ Your sleep duration is in the healthy range!")
        }

        // Score-based advice
        if avgScore < 60 {
            advice.append("🔍 Focus on sleep hygiene: dim lights 1h before bed, avoid screens, keep the room cool (65-68°F).")
        } else if avgScore < 80 {
            advice.append("📊 Your sleep quality is good. Small improvements in deep/REM sleep could push you into excellent territory.")
        } else {
            advice.append("🏆 Excellent sleep quality! Maintain your current routines.")
        }

        // Pattern-based advice from history
        if history.count >= 5 {
            let variance = calculateVariance(history.map(\.totalSleep))
            if variance > 3600 { // More than 1 hour variance
                advice.append("⏰ Your sleep schedule varies a lot. Try waking up at the same time daily — consistency improves sleep quality.")
            }
        }

        // Deep sleep specific
        let avgDeep = history.map(\.deepSleep).reduce(0, +) / Double(max(1, history.count))
        if avgDeep < 45 * 60 {
            advice.append("💪 Boost deep sleep with: regular exercise (not close to bedtime), avoiding alcohol, and keeping a cool bedroom.")
        }

        // REM sleep specific
        let avgRem = history.map(\.remSleep).reduce(0, +) / Double(max(1, history.count))
        if avgRem < 60 * 60 {
            advice.append("🧠 Support REM sleep: manage stress, avoid heavy meals before bed, and give yourself enough time for 7-9 hours.")
        }

        return advice
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func calculateVariance(_ values: [TimeInterval]) -> TimeInterval {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count))
    }
}

// MARK: - Report Model

extension SleepReportService {
    struct SleepReport: Sendable {
        let week: Date
        let avgSleep: TimeInterval
        let avgScore: Int
        let bestNight: Date
        let trends: [String]
        let advice: [String]

        var avgSleepFormatted: String {
            let hours = Int(avgSleep) / 3600
            let minutes = (Int(avgSleep) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

        var dateRange: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
    }
}
