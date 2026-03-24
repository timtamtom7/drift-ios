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

        // Generate correlations
        let correlations = generateCorrelations(from: weekRecords)

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
            hrvAverage: hrvAverage,
            correlations: correlations
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

    private func generateCorrelations(from records: [SleepRecord]) -> [WeeklyReport.CorrelationInsight] {
        var correlations: [WeeklyReport.CorrelationInsight] = []

        // Only generate correlations if we have enough data
        let recordsWithCaffeine = records.filter { $0.caffeineMg != nil }
        let recordsWithExercise = records.filter { $0.exerciseMinutes != nil }
        let recordsWithMindful = records.filter { $0.mindfulMinutes != nil }

        // Caffeine correlation
        if recordsWithCaffeine.count >= 3 {
            let caffeineCorrelation = analyzeCaffeineCorrelation(records: recordsWithCaffeine)
            if let corr = caffeineCorrelation {
                correlations.append(corr)
            }
        }

        // Exercise correlation
        if recordsWithExercise.count >= 3 {
            let exerciseCorrelation = analyzeExerciseCorrelation(records: recordsWithExercise)
            if let corr = exerciseCorrelation {
                correlations.append(corr)
            }
        }

        // Mindful correlation
        if recordsWithMindful.count >= 3 {
            let mindfulCorrelation = analyzeMindfulCorrelation(records: recordsWithMindful)
            if let corr = mindfulCorrelation {
                correlations.append(corr)
            }
        }

        return correlations
    }

    private func analyzeCaffeineCorrelation(records: [SleepRecord]) -> WeeklyReport.CorrelationInsight? {
        // Group by high caffeine (>200mg) vs low caffeine (<=200mg)
        let highCaffeine = records.filter { ($0.caffeineMg ?? 0) > 200 }
        let lowCaffeine = records.filter { ($0.caffeineMg ?? 0) <= 200 }

        guard !highCaffeine.isEmpty && !lowCaffeine.isEmpty else { return nil }

        let avgScoreHigh = highCaffeine.map { $0.score }.reduce(0, +) / highCaffeine.count
        let avgScoreLow = lowCaffeine.map { $0.score }.reduce(0, +) / lowCaffeine.count

        let diff = avgScoreLow - avgScoreHigh

        if abs(diff) < 5 { return nil } // Not meaningful

        let isPositive = diff > 0
        let strength: WeeklyReport.CorrelationInsight.CorrelationStrength
        if abs(diff) > 10 {
            strength = .strong
        } else if abs(diff) > 5 {
            strength = .moderate
        } else {
            strength = .weak
        }

        let description: String
        if isPositive {
            let avgCaffeineHigh = highCaffeine.map { $0.caffeineMg ?? 0.0 }.reduce(0.0, +) / Double(highCaffeine.count)
            description = "Your sleep scores are \(abs(diff)) points lower on days with >\(Int(avgCaffeineHigh))mg caffeine. Try limiting caffeine after 2pm."
        } else {
            description = "Interestingly, your sleep was slightly better on higher caffeine days. This might be because good sleep makes you more energetic the next day."
        }

        return WeeklyReport.CorrelationInsight(
            id: UUID(),
            factor: "Caffeine",
            description: description,
            strength: strength,
            emoji: "☕"
        )
    }

    private func analyzeExerciseCorrelation(records: [SleepRecord]) -> WeeklyReport.CorrelationInsight? {
        // Group by exercised (>30 min) vs not exercised
        let exercised = records.filter { ($0.exerciseMinutes ?? 0) > 30 }
        let rested = records.filter { ($0.exerciseMinutes ?? 0) <= 30 }

        guard !exercised.isEmpty && !rested.isEmpty else { return nil }

        let avgScoreExercised = exercised.map { $0.score }.reduce(0, +) / exercised.count
        let avgScoreRested = rested.map { $0.score }.reduce(0, +) / rested.count

        let diff = avgScoreExercised - avgScoreRested

        if abs(diff) < 5 { return nil }

        let isPositive = diff > 0
        let strength: WeeklyReport.CorrelationInsight.CorrelationStrength
        if abs(diff) > 12 {
            strength = .strong
        } else if abs(diff) > 7 {
            strength = .moderate
        } else {
            strength = .weak
        }

        let description: String
        if isPositive {
            description = "Days when you exercised for 30+ minutes led to \(abs(diff))-point higher sleep scores. Keep moving — it pays off at night."
        } else {
            description = "Your sleep scores were slightly lower after exercise days. Make sure you're giving yourself time to wind down after workouts."
        }

        return WeeklyReport.CorrelationInsight(
            id: UUID(),
            factor: "Exercise",
            description: description,
            strength: strength,
            emoji: "🏃"
        )
    }

    private func analyzeMindfulCorrelation(records: [SleepRecord]) -> WeeklyReport.CorrelationInsight? {
        let mindful = records.filter { ($0.mindfulMinutes ?? 0) > 0 }
        let notMindful = records.filter { ($0.mindfulMinutes ?? 0) == 0 }

        guard !mindful.isEmpty && !notMindful.isEmpty else { return nil }

        let avgScoreMindful = mindful.map { $0.score }.reduce(0, +) / mindful.count
        let avgScoreNotMindful = notMindful.map { $0.score }.reduce(0, +) / notMindful.count

        let diff = avgScoreMindful - avgScoreNotMindful

        if abs(diff) < 5 { return nil }

        let isPositive = diff > 0
        let strength: WeeklyReport.CorrelationInsight.CorrelationStrength
        if abs(diff) > 10 {
            strength = .strong
        } else if abs(diff) > 5 {
            strength = .moderate
        } else {
            strength = .weak
        }

        let description: String
        if isPositive {
            description = "Days with mindfulness sessions led to \(abs(diff))-point higher sleep scores. Even 5 minutes of meditation helps."
        } else {
            description = "Mindfulness didn't show a clear benefit this week. The relationship between mindfulness and sleep often takes longer to emerge."
        }

        return WeeklyReport.CorrelationInsight(
            id: UUID(),
            factor: "Mindfulness",
            description: description,
            strength: strength,
            emoji: "🧘"
        )
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
