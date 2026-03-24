import Foundation

@MainActor
class WeeklyReportService: ObservableObject {
    @Published var currentReport: WeeklyReport?
    @Published var isGenerating = false
    @Published var error: String?

    private let databaseService = DatabaseService()

    // Generate a weekly report for the week ending today (or the most recent Sunday)
    func generateWeeklyReport(from records: [SleepRecord]) async -> WeeklyReport? {
        isGenerating = true
        error = nil
        defer { isGenerating = false }

        let calendar = Calendar.current
        let now = Date()

        // Find the most recent Sunday (report week ends on Sunday)
        let todayWeekday = calendar.component(.weekday, from: now)
        let daysSinceSunday = todayWeekday == 1 ? 0 : todayWeekday - 1
        let weekEndDate = calendar.date(byAdding: .day, value: -daysSinceSunday, to: now) ?? now
        let weekStartDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: weekEndDate)) ?? weekEndDate

        // Filter records to this week
        let weekRecords = records.filter { record in
            record.date >= calendar.startOfDay(for: weekStartDate) &&
            record.date <= calendar.startOfDay(for: weekEndDate)
        }.sorted { $0.date < $1.date }

        guard weekRecords.count >= 3 else {
            error = "Need at least 3 nights of sleep data to generate a weekly report"
            return nil
        }

        // Calculate averages
        let avgScore = weekRecords.map { $0.score }.reduce(0, +) / weekRecords.count
        let avgHours = weekRecords.map { $0.totalDuration / 3600 }.reduce(0, +) / Double(weekRecords.count)
        let avgDeep = weekRecords.map { $0.deepSleepMinutes }.reduce(0, +) / weekRecords.count
        let avgRem = weekRecords.map { $0.remSleepMinutes }.reduce(0, +) / weekRecords.count

        // Best and worst nights
        let bestNightRecord = weekRecords.max(by: { $0.score < $1.score })
        let worstNightRecord = weekRecords.min(by: { $0.score < $1.score })

        let bestNight: WeeklyReport.NightSummary?
        if let best = bestNightRecord {
            bestNight = WeeklyReport.NightSummary(
                date: best.date,
                score: best.score,
                hours: best.totalHoursFormatted
            )
        } else {
            bestNight = nil
        }

        let worstNight: WeeklyReport.NightSummary?
        if let worst = worstNightRecord {
            worstNight = WeeklyReport.NightSummary(
                date: worst.date,
                score: worst.score,
                hours: worst.totalHoursFormatted
            )
        } else {
            worstNight = nil
        }

        // HRV average
        let hrvRecords = weekRecords.filter { $0.hrvAvg != nil }
        let hrvAverage = hrvRecords.isEmpty ? nil : hrvRecords.compactMap { $0.hrvAvg }.reduce(0, +) / Double(hrvRecords.count)

        // Generate insights
        let insights = generateInsights(
            records: weekRecords,
            avgScore: avgScore,
            avgHours: avgHours,
            avgDeep: avgDeep,
            avgRem: avgRem
        )

        // Determine trend
        let trend = determineTrend(records: records, currentWeekRecords: weekRecords)

        let report = WeeklyReport(
            id: UUID(),
            weekStartDate: calendar.startOfDay(for: weekStartDate),
            weekEndDate: calendar.startOfDay(for: weekEndDate),
            generatedAt: now,
            averageScore: avgScore,
            averageHours: avgHours,
            totalNights: weekRecords.count,
            averageDeepMinutes: avgDeep,
            averageRemMinutes: avgRem,
            bestNight: bestNight,
            worstNight: worstNight,
            insights: insights,
            trend: trend,
            hrvAverage: hrvAverage
        )

        // Save to database
        do {
            try databaseService.saveWeeklyReport(report)
            currentReport = report
        } catch {
            self.error = "Failed to save weekly report: \(error.localizedDescription)"
        }

        return report
    }

    func loadExistingReport(for weekStartDate: Date) -> WeeklyReport? {
        try? databaseService.fetchWeeklyReport(for: weekStartDate)
    }

    func loadLatestReport() -> WeeklyReport? {
        let reports = (try? databaseService.fetchWeeklyReports()) ?? []
        return reports.first
    }

    private func generateInsights(
        records: [SleepRecord],
        avgScore: Int,
        avgHours: Double,
        avgDeep: Int,
        avgRem: Int
    ) -> [String] {
        var insights: [String] = []

        // Score insight
        if avgScore >= 82 {
            insights.append("You had a great week of sleep with an average score of \(avgScore). Your consistency is paying off!")
        } else if avgScore >= 70 {
            insights.append("Your average score of \(avgScore) is solid. A few adjustments could push you into excellent territory.")
        } else if avgScore < 65 {
            insights.append("Your average score of \(avgScore) suggests this was a tough week for sleep. Sleep quality often reflects overall wellness — consider what might be affecting your rest.")
        }

        // Duration insight
        if avgHours < 6.5 {
            insights.append("You're averaging only \(String(format: "%.1f", avgHours)) hours per night. Most adults need 7-9 hours. Even one extra night of full sleep can make a big difference.")
        } else if avgHours >= 7.5 && avgScore >= 75 {
            insights.append("You're getting plenty of sleep at \(String(format: "%.1f", avgHours)) hours per night. Quality and quantity are both there.")
        }

        // Deep sleep insight
        if avgDeep < 50 {
            insights.append("Your deep sleep is averaging only \(avgDeep) minutes per night. Deep sleep is when your body repairs itself — consider reducing evening alcohol or caffeine to improve this.")
        } else if avgDeep >= 80 {
            insights.append("Excellent deep sleep at \(avgDeep) minutes per night. Your body is getting the restoration it needs.")
        }

        // REM sleep insight
        if avgRem < 60 {
            insights.append("REM sleep at \(avgRem) minutes is on the lower side. REM is essential for memory and emotional health — try to wind down earlier to get more of it.")
        } else if avgRem >= 90 {
            insights.append("Great REM sleep at \(avgRem) minutes per night. Your brain is processing and consolidating memories effectively.")
        }

        // Best night context
        if let best = records.max(by: { $0.score < $1.score }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            insights.append("Your best night was \(formatter.string(from: best.date)) with a score of \(best.score). Look at what you did differently that day — it might be worth repeating.")
        }

        return insights
    }

    private func determineTrend(records: [SleepRecord], currentWeekRecords: [SleepRecord]) -> WeeklyReport.TrendDirection {
        let calendar = Calendar.current

        // Get previous week's records
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        let previousWeekRecords = records.filter { record in
            record.date >= calendar.startOfDay(for: twoWeeksAgo) &&
            record.date < calendar.startOfDay(for: oneWeekAgo)
        }

        guard !previousWeekRecords.isEmpty else { return .stable }

        let currentAvg = currentWeekRecords.map { $0.score }.reduce(0, +) / currentWeekRecords.count
        let previousAvg = previousWeekRecords.map { $0.score }.reduce(0, +) / previousWeekRecords.count

        let diff = currentAvg - previousAvg
        if diff > 5 {
            return .up
        } else if diff < -5 {
            return .down
        } else {
            return .stable
        }
    }
}
