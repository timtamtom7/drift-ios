import Foundation
import NaturalLanguage

actor AIInsightService {
    private var historicalRecords: [SleepRecord] = []

    func setHistoricalRecords(_ records: [SleepRecord]) {
        self.historicalRecords = records
    }

    func generateInsight(for record: SleepRecord) async -> SleepInsight {
        var insights: [String] = []
        var isPositive = true

        // Deep sleep analysis
        let deepAvg = historicalRecords.isEmpty ? record.deepSleepMinutes :
            historicalRecords.map { $0.deepSleepMinutes }.reduce(0, +) / historicalRecords.count

        let remAvg = historicalRecords.isEmpty ? record.remSleepMinutes :
            historicalRecords.filter { !$0.stages.isEmpty }.map { $0.remSleepMinutes }.reduce(0, +) / max(1, historicalRecords.filter { !$0.stages.isEmpty }.count)

        let deepDiff = record.deepSleepMinutes - deepAvg
        if abs(deepDiff) <= 5 {
            if record.deepSleepMinutes >= 60 {
                insights.append("Your deep sleep was solid at \(record.deepSleepMinutes) minutes. This is the sleep that repairs muscles and strengthens immunity — your body had what it needed tonight.")
                isPositive = true
            } else {
                insights.append("Your deep sleep was around average. Consider winding down 30 minutes earlier to give your body more time in this restorative phase.")
                isPositive = false
            }
        } else if deepDiff > 5 {
            insights.append("Your deep sleep was \(deepDiff) minutes above average tonight. This is the kind of night that leaves you feeling genuinely restored.")
            isPositive = true
        } else {
            insights.append("Your deep sleep was \(abs(deepDiff)) minutes below average. Late caffeine or alcohol are common culprits — even one glass can suppress this phase.")
            isPositive = false
        }

        // REM sleep analysis
        let remDiff = record.remSleepMinutes - remAvg
        if remDiff > 10 && insights.isEmpty {
            insights.append("Your REM sleep was \(remDiff) minutes higher than usual. This is the phase tied to learning and emotional processing — you may wake up with unusual clarity.")
            isPositive = true
        }

        // Sleep duration analysis
        let totalMinutes = Int(record.totalDuration / 60)
        if totalMinutes < 360 {
            insights.append("Under 6 hours of sleep. This is in the range where reaction time and decision-making start to suffer noticeably. Your body needed more.")
            isPositive = false
        } else if totalMinutes >= 420 && totalMinutes <= 540 && record.score >= 80 {
            insights.append("You hit the 7-9 hour sweet spot with a score of \(record.score). This is the sleep duration most adults thrive on.")
            isPositive = true
        }

        // Awake time analysis
        if record.awakeMinutes > 45 {
            insights.append("You spent \(record.awakeMinutes) minutes awake during the night — more than usual. If this was a one-off, don't worry. If it keeps happening, it might be worth looking at your bedroom temperature (65-68°F is ideal).")
            isPositive = false
        }

        // Timing analysis
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: record.fellAsleepTime)
        if hour >= 23 || hour < 1 {
            insights.append("You fell asleep after midnight. While sleep quality matters more than timing, consistently late bedtimes can shift your circadian rhythm and make mornings harder.")
            isPositive = false
        }

        // Weekly trend
        if historicalRecords.count >= 3 {
            let recentRecords = Array(historicalRecords.suffix(3))
            let recentAvgDuration = recentRecords.map { $0.totalDuration }.reduce(0, +) / Double(recentRecords.count)
            if record.totalDuration < recentAvgDuration - 600 {
                insights.append("You've been sleeping less than usual this week. If you're feeling more irritable or foggy during the day, this could be why.")
                isPositive = false
            }
        }

        // Score-based insight
        if record.score >= 85 && insights.allSatisfy({ insight in
            !insight.contains("below average") && !insight.contains("needed more")
        }) {
            insights.append("Score of \(record.score) — a genuinely good night's sleep. You should feel the difference today.")
            isPositive = true
        } else if record.score < 60 {
            insights.append("A rough night. Sleep debt accumulates — try to get an extra 30-60 minutes over the next couple of days rather than sleeping in until noon (which can throw off your rhythm further).")
            isPositive = false
        }

        // ===== Round 5: AI Correlations =====

        // 1. Consecutive sleep correlation: "Your best sleep was after a 7+ hour night before"
        if let consecutiveInsight = await analyzeConsecutiveSleepCorrelation(for: record) {
            insights.append(consecutiveInsight)
        }

        // 2. Seasonal pattern: "Your sleep is X min shorter in winter"
        if let seasonalInsight = await analyzeSeasonalPattern(for: record) {
            insights.append(seasonalInsight)
        }

        // 3. Exercise correlation: "You slept 20% better on days you exercised"
        if let exerciseInsight = await analyzeExerciseCorrelation(for: record) {
            insights.append(exerciseInsight)
        }

        let finalText = insights.first ?? "A quiet night. Your sleep was consistent and steady."
        return SleepInsight(text: finalText, isPositive: isPositive)
    }

    /// Generate a list of AI correlation insights for the weekly report
    func generateCorrelationInsights() async -> [SleepInsight] {
        var insights: [SleepInsight] = []

        // Exercise correlation
        if let exerciseInsight = await analyzeGlobalExerciseCorrelation() {
            insights.append(exerciseInsight)
        }

        // Alcohol/caffeine correlation
        if let alcoholInsight = await analyzeAlcoholCorrelation() {
            insights.append(alcoholInsight)
        }

        // Consecutive sleep pattern
        if let consecutiveInsight = await analyzeGlobalConsecutiveSleepCorrelation() {
            insights.append(consecutiveInsight)
        }

        // Seasonal pattern
        if let seasonalInsight = await analyzeGlobalSeasonalPattern() {
            insights.append(seasonalInsight)
        }

        return insights
    }

    // MARK: - Round 5 Correlation Analysis

    /// Analyze if sleeping 7+ hours the previous night correlates with better sleep
    private func analyzeConsecutiveSleepCorrelation(for record: SleepRecord) async -> String? {
        guard historicalRecords.count >= 5 else { return nil }

        let calendar = Calendar.current

        // Find the previous night's record
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: record.date) else { return nil }
        let previousDayStart = calendar.startOfDay(for: previousDay)

        guard let previousRecord = historicalRecords.first(where: { calendar.isDate($0.date, inSameDayAs: previousDayStart) }) else {
            return nil
        }

        let previousNightHours = previousRecord.totalDuration / 3600
        let currentScore = record.score
        let previousScore = previousRecord.score

        // Check if previous night was 7+ hours and current night was better
        if previousNightHours >= 7 && currentScore > previousScore + 10 {
            let improvement = currentScore - previousScore
            return "Your best sleep often comes after a full night's rest. Tonight's score was \(improvement) points higher than after a short previous night."
        }

        // Check if previous night was short and current night suffered
        if previousNightHours < 6 && currentScore < previousScore - 5 {
            let decline = previousScore - currentScore
            return "Sleep debt from the night before (\(Int(previousNightHours))h) may have affected tonight. Your score was \(decline) points lower."
        }

        return nil
    }

    /// Analyze seasonal patterns in sleep duration
    private func analyzeSeasonalPattern(for record: SleepRecord) async -> String? {
        guard historicalRecords.count >= 10 else { return nil }

        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: record.date)

        // Group records by season
        let winterRecords = historicalRecords.filter {
            let month = calendar.component(.month, from: $0.date)
            return month == 12 || month == 1 || month == 2
        }

        let summerRecords = historicalRecords.filter {
            let month = calendar.component(.month, from: $0.date)
            return month == 6 || month == 7 || month == 8
        }

        guard !winterRecords.isEmpty && !summerRecords.isEmpty else { return nil }

        let winterAvgMinutes = winterRecords.map { $0.totalDuration / 60.0 }.reduce(0.0, +) / Double(winterRecords.count)
        let summerAvgMinutes = summerRecords.map { $0.totalDuration / 60.0 }.reduce(0.0, +) / Double(summerRecords.count)

        let diff = winterAvgMinutes - summerAvgMinutes
        let absDiff = abs(Int(diff))

        // Only report meaningful differences (>15 minutes)
        if absDiff > 15 {
            if diff < 0 {
                // Sleep is shorter in winter
                return "Your sleep follows a seasonal pattern — you're averaging \(absDiff) minutes less per night in winter compared to summer. Light exposure in the morning can help counteract this."
            } else {
                return "Interestingly, your sleep tends to be \(absDiff) minutes longer in winter. Cool, darker evenings may be helping you sleep more."
            }
        }

        return nil
    }

    /// Analyze correlation between exercise and sleep quality
    private func analyzeExerciseCorrelation(for record: SleepRecord) async -> String? {
        guard historicalRecords.count >= 5 else { return nil }

        let exercised = historicalRecords.filter { ($0.exerciseMinutes ?? 0) > 30 }
        let notExercised = historicalRecords.filter { ($0.exerciseMinutes ?? 0) <= 30 }

        guard exercised.count >= 2 && notExercised.count >= 2 else { return nil }

        let avgScoreExercised = exercised.map { $0.score }.reduce(0, +) / exercised.count
        let avgScoreNotExercised = notExercised.map { $0.score }.reduce(0, +) / notExercised.count

        let diff = avgScoreExercised - avgScoreNotExercised

        // Check if current record follows this pattern
        let currentExercised = (record.exerciseMinutes ?? 0) > 30
        let expectedScore = currentExercised ? avgScoreExercised : avgScoreNotExercised
        let actualVsExpected = record.score - expectedScore

        if abs(diff) >= 8 {
            let percentBetter = Int((Double(diff) / Double(avgScoreNotExercised)) * 100)
            if diff > 0 {
                return "You're \(percentBetter)% more likely to have better sleep on days you exercise 30+ minutes. Tonight fits that pattern."
            } else {
                return "Interestingly, your sleep scores tend to be lower on exercise days. Make sure you're winding down properly after workouts."
            }
        }

        return nil
    }

    // MARK: - Global Correlation Analysis (for weekly/monthly reports)

    /// Global exercise correlation across all historical data
    private func analyzeGlobalExerciseCorrelation() async -> SleepInsight? {
        guard historicalRecords.count >= 5 else { return nil }

        let exercised = historicalRecords.filter { ($0.exerciseMinutes ?? 0) > 30 }
        let notExercised = historicalRecords.filter { ($0.exerciseMinutes ?? 0) <= 30 }

        guard exercised.count >= 2 && notExercised.count >= 2 else { return nil }

        let avgScoreExercised = exercised.map { $0.score }.reduce(0, +) / exercised.count
        let avgScoreNotExercised = notExercised.map { $0.score }.reduce(0, +) / notExercised.count

        let diff = avgScoreExercised - avgScoreNotExercised

        guard abs(diff) >= 5 else { return nil }

        if diff > 0 {
            let percentBetter = Int(round((Double(diff) / Double(avgScoreNotExercised)) * 100))
            return SleepInsight(
                text: "You slept \(percentBetter)% better on days you exercised for 30+ minutes. Keep moving — it clearly pays off at night.",
                isPositive: true
            )
        } else {
            return SleepInsight(
                text: "Your sleep scores tend to be lower after exercise days. Make sure you're allowing enough wind-down time after workouts.",
                isPositive: false
            )
        }
    }

    /// Analyze alcohol impact on deep sleep
    private func analyzeAlcoholCorrelation() async -> SleepInsight? {
        // Note: SleepRecord doesn't have an explicit alcohol field
        // But caffeine after 8pm is a proxy for late-night consumption
        // In a full implementation, we'd add alcohol tracking

        // For now, analyze caffeine timing as a proxy
        // Records with high caffeine (>200mg) and late sleep times
        guard historicalRecords.count >= 5 else { return nil }

        let highCaffeine = historicalRecords.filter { ($0.caffeineMg ?? 0) > 200 }
        let lowCaffeine = historicalRecords.filter { ($0.caffeineMg ?? 0) <= 200 }

        guard highCaffeine.count >= 2 && lowCaffeine.count >= 2 else { return nil }

        let avgDeepHigh = highCaffeine.map { $0.deepSleepMinutes }.reduce(0, +) / highCaffeine.count
        let avgDeepLow = lowCaffeine.map { $0.deepSleepMinutes }.reduce(0, +) / lowCaffeine.count

        let diff = avgDeepLow - avgDeepHigh

        if diff >= 10 {
            let percentReduction = Int((Double(diff) / Double(avgDeepLow)) * 100)
            return SleepInsight(
                text: "Nights with >200mg caffeine show \(percentReduction)% less deep sleep on average. Even one cup after 2pm can suppress deep sleep — the most restorative phase.",
                isPositive: false
            )
        }

        return nil
    }

    /// Global consecutive sleep pattern analysis
    private func analyzeGlobalConsecutiveSleepCorrelation() async -> SleepInsight? {
        guard historicalRecords.count >= 7 else { return nil }

        let calendar = Calendar.current
        let sortedRecords = historicalRecords.sorted { $0.date < $1.date }

        var afterFullNight: [Int] = []
        var afterShortNight: [Int] = []

        for i in 1..<sortedRecords.count {
            let current = sortedRecords[i]
            let previous = sortedRecords[i - 1]

            let previousHours = previous.totalDuration / 3600
            let currentScore = current.score

            if previousHours >= 7 {
                afterFullNight.append(currentScore)
            } else if previousHours < 6 {
                afterShortNight.append(currentScore)
            }
        }

        guard afterFullNight.count >= 2 && afterShortNight.count >= 2 else { return nil }

        let avgAfterFull = afterFullNight.reduce(0, +) / afterFullNight.count
        let avgAfterShort = afterShortNight.reduce(0, +) / afterShortNight.count

        let diff = avgAfterFull - avgAfterShort

        if diff >= 8 {
            return SleepInsight(
                text: "You consistently score \(diff) points higher after a 7+ hour night versus a sub-6 hour night. Sleep is a cumulative process — one good night sets up the next.",
                isPositive: true
            )
        } else if diff <= -8 {
            return SleepInsight(
                text: "Sleep debt is real. After short nights, your scores are \(abs(diff)) points lower on average. Prioritizing recovery sleep matters.",
                isPositive: false
            )
        }

        return nil
    }

    /// Global seasonal pattern analysis
    private func analyzeGlobalSeasonalPattern() async -> SleepInsight? {
        guard historicalRecords.count >= 15 else { return nil }

        let calendar = Calendar.current

        // Group by season
        let winterRecords = historicalRecords.filter {
            let month = calendar.component(.month, from: $0.date)
            return month == 12 || month == 1 || month == 2
        }

        let springRecords = historicalRecords.filter {
            let month = calendar.component(.month, from: $0.date)
            return month == 3 || month == 4 || month == 5
        }

        let summerRecords = historicalRecords.filter {
            let month = calendar.component(.month, from: $0.date)
            return month == 6 || month == 7 || month == 8
        }

        let fallRecords = historicalRecords.filter {
            let month = calendar.component(.month, from: $0.date)
            return month == 9 || month == 10 || month == 11
        }

        let seasons: [(name: String, records: [SleepRecord])] = [
            ("winter", winterRecords),
            ("spring", springRecords),
            ("summer", summerRecords),
            ("fall", fallRecords)
        ]

        var seasonalDurations: [(season: String, avgMinutes: Int)] = []
        for (name, recs) in seasons where !recs.isEmpty {
            let avg = recs.map { Int($0.totalDuration / 60) }.reduce(0, +) / recs.count
            seasonalDurations.append((name, avg))
        }

        guard seasonalDurations.count >= 2 else { return nil }

        // Find shortest and longest seasons
        let sorted = seasonalDurations.sorted { $0.avgMinutes < $1.avgMinutes }
        let shortest = sorted.first!
        let longest = sorted.last!
        let diff = longest.avgMinutes - shortest.avgMinutes

        if diff >= 20 {
            return SleepInsight(
                text: "Your sleep follows seasonal patterns — you're averaging \(diff) minutes per night less in \(shortest.season) compared to \(longest.season). This is common and tied to daylight exposure.",
                isPositive: diff > 0
            )
        }

        return nil
    }

    func generateWeeklySummary() async -> [SleepInsight] {
        guard historicalRecords.count >= 3 else { return [] }

        var insights: [SleepInsight] = []
        let scores = historicalRecords.map { $0.score }
        let avgScore = scores.reduce(0, +) / scores.count

        let durations = historicalRecords.map { $0.totalDuration / 3600 }
        let avgHours = durations.reduce(0, +) / Double(durations.count)

        let deepAvg = historicalRecords.map { $0.deepSleepMinutes }.reduce(0, +) / historicalRecords.count

        if avgScore >= 82 {
            insights.append(SleepInsight(
                text: "You've been sleeping really well this week — average score of \(avgScore). Whatever you're doing differently, it's working.",
                isPositive: true
            ))
        } else if avgScore < 65 {
            insights.append(SleepInsight(
                text: "This week's average score is \(avgScore) — below your baseline. Sleep quality often reflects lifestyle. What changed this week?",
                isPositive: false
            ))
        }

        if avgHours < 6.5 {
            insights.append(SleepInsight(
                text: "Average sleep this week: \(String(format: "%.1f", avgHours)) hours. Most adults function best at 7-9 hours. Even one extra night of full sleep makes a measurable difference.",
                isPositive: false
            ))
        }

        if deepAvg < 50 && historicalRecords.count >= 4 {
            insights.append(SleepInsight(
                text: "Your deep sleep has been consistently low this week. Deep sleep is when your body repairs itself — consider reducing evening alcohol, which is known to suppress it.",
                isPositive: false
            ))
        }

        // Best/worst day
        if let best = historicalRecords.max(by: { $0.score < $1.score }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            insights.append(SleepInsight(
                text: "Your best night this week was \(formatter.string(from: best.date)) (\(best.score)). Look at what you did differently that day — sleep isn't random.",
                isPositive: true
            ))
        }

        // Add Round 5 correlation insights
        let correlationInsights = await generateCorrelationInsights()
        insights.append(contentsOf: correlationInsights.prefix(2))

        return insights
    }
}

extension SleepRecord {
    var totalMinutesFormatted: String {
        let minutes = Int(totalDuration / 60)
        return "\(minutes)m"
    }
}
