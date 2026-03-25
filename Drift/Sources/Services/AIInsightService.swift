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

    // MARK: - R7: Deep Sleep Analysis

    /// Generate comprehensive R7 deep sleep analysis
    func generateDeepAnalysis(for record: SleepRecord) async -> DeepSleepAnalysis {
        let sleepDebt = calculateSleepDebt(for: record)
        let bestWindow = detectBestSleepWindow()
        let patterns = detectPatterns(for: record)
        let weeklyTrend = calculateWeeklyTrend()
        let stageSummaries = generateStageSummaries()
        let snoringRisk = assessSnoringRisk(for: record)
        let breathing = assessBreathingRegularity(for: record)
        let predictedScore = predictNextScore()

        return DeepSleepAnalysis(
            sleepDebtMinutes: sleepDebt,
            bestSleepWindow: bestWindow,
            detectedPatterns: patterns,
            weeklyTrend: weeklyTrend,
            recommendations: generateRecommendations(for: record),
            sleepStagesSummary: stageSummaries,
            snoringRisk: snoringRisk,
            breathingRegularity: breathing,
            predictedNextScore: predictedScore
        )
    }

    /// Calculate sleep debt compared to 8hr (480min) target
    private func calculateSleepDebt(for record: SleepRecord) -> Int {
        let targetMinutes = 480
        let actualMinutes = record.totalMinutes
        return max(0, targetMinutes - actualMinutes)
    }

    /// Detect the best sleep window based on historical data
    private func detectBestSleepWindow() -> String? {
        guard historicalRecords.count >= 3 else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var sleepWindows: [String: [Int]] = [:]

        for record in historicalRecords {
            let sleepHour = Calendar.current.component(.hour, from: record.fellAsleepTime)
            let window: String
            if sleepHour >= 21 || sleepHour < 3 {
                window = "Early (9pm-midnight)"
            } else if sleepHour >= 3 && sleepHour < 6 {
                window = "Late (3am-6am)"
            } else {
                window = "Average"
            }

            sleepWindows[window, default: []].append(record.score)
        }

        // Find best window by average score
        var bestWindow: String?
        var bestAvg = 0
        for (window, scores) in sleepWindows {
            let avg = scores.reduce(0, +) / max(1, scores.count)
            if avg > bestAvg {
                bestAvg = avg
                bestWindow = window
            }
        }

        // Format as time range
        if bestWindow == "Early (9pm-midnight)" {
            return "10pm-6am"
        } else if bestWindow == "Late (3am-6am)" {
            return "12am-8am"
        }
        return "11pm-7am"
    }

    /// Detect patterns in sleep behavior
    private func detectPatterns(for record: SleepRecord) -> [String] {
        var patterns: [String] = []

        guard historicalRecords.count >= 3 else { return patterns }

        let recent = Array(historicalRecords.suffix(5))

        // Weekend vs weekday consistency
        let weekdayRecords = recent.filter { Calendar.current.isDateInWeekend($0.date) == false }
        let weekendRecords = recent.filter { Calendar.current.isDateInWeekend($0.date) }

        if !weekdayRecords.isEmpty && !weekendRecords.isEmpty {
            let weekdayAvg = weekdayRecords.map { $0.score }.reduce(0, +) / weekdayRecords.count
            let weekendAvg = weekendRecords.map { $0.score }.reduce(0, +) / weekendRecords.count

            if weekendAvg > weekdayAvg + 10 {
                patterns.append("Sleep better on weekends")
            } else if weekdayAvg > weekendAvg + 10 {
                patterns.append("Weekday sleep is better")
            } else {
                patterns.append("Consistent sleep quality")
            }
        }

        // Deep sleep consistency
        let deepScores = recent.map { $0.deepSleepMinutes }
        if deepScores.count >= 2 {
            let variance = deepScores.reduce(0) { $0 + abs($1 - (deepScores.reduce(0, +) / deepScores.count)) }
            if variance < 10 {
                patterns.append("Stable deep sleep")
            } else {
                patterns.append("Variable deep sleep")
            }
        }

        // Early riser or night owl
        let sleepHours = recent.map { Calendar.current.component(.hour, from: $0.fellAsleepTime) }
        let avgHour = sleepHours.reduce(0, +) / sleepHours.count
        if avgHour >= 23 || avgHour < 1 {
            patterns.append("Night owl tendency")
        } else if avgHour >= 21 && avgHour < 23 {
            patterns.append("Early sleeper")
        }

        return patterns
    }

    /// Calculate weekly trend
    private func calculateWeeklyTrend() -> String {
        guard historicalRecords.count >= 4 else { return "Not enough data" }

        let recent = Array(historicalRecords.suffix(7))
        guard recent.count >= 4 else { return "Not enough data" }

        let halfPoint = recent.count / 2
        let firstHalf = Array(recent.prefix(halfPoint))
        let secondHalf = Array(recent.suffix(halfPoint))

        let firstAvg = firstHalf.map { $0.score }.reduce(0, +) / firstHalf.count
        let secondAvg = secondHalf.map { $0.score }.reduce(0, +) / secondHalf.count

        let diff = secondAvg - firstAvg
        if diff > 5 { return "Improving" }
        if diff < -5 { return "Declining" }
        return "Stable"
    }

    /// Generate sleep stage summaries
    private func generateStageSummaries() -> [SleepStageSummary] {
        guard historicalRecords.count >= 3 else { return [] }

        let deepAvg = historicalRecords.map { $0.deepSleepMinutes }.reduce(0, +) / historicalRecords.count
        let remAvg = historicalRecords.map { $0.remSleepMinutes }.reduce(0, +) / historicalRecords.count
        let lightAvg = historicalRecords.map { $0.lightSleepMinutes }.reduce(0, +) / historicalRecords.count

        return [
            SleepStageSummary(stage: "deep", avgMinutes: deepAvg, trend: deepAvg >= 90 ? "above_avg" : (deepAvg < 60 ? "below_avg" : "normal")),
            SleepStageSummary(stage: "rem", avgMinutes: remAvg, trend: remAvg >= 90 ? "above_avg" : (remAvg < 60 ? "below_avg" : "normal")),
            SleepStageSummary(stage: "light", avgMinutes: lightAvg, trend: "normal")
        ]
    }

    /// Assess snoring risk based on respiratory data
    private func assessSnoringRisk(for record: SleepRecord) -> String? {
        guard let spo2 = record.spo2Avg else { return nil }

        // Low SpO2 indicates potential snoring/breathing issues
        if spo2 < 93 { return "High" }
        if spo2 < 95 { return "Medium" }
        return "Low"
    }

    /// Assess breathing regularity from respiratory rate
    private func assessBreathingRegularity(for record: SleepRecord) -> String? {
        guard record.hasRespiratoryData else { return nil }

        // High variability in respiratory rate could indicate breathing issues
        // Simple heuristic: if awake time is high and respiratory data exists, flag as irregular
        if record.awakeMinutes > 45 { return "Irregular" }
        return "Regular"
    }

    /// Simple ML-like prediction of next night's score
    private func predictNextScore() -> Int? {
        guard historicalRecords.count >= 5 else { return nil }

        let recent = Array(historicalRecords.suffix(5))
        let scores = recent.map { $0.score }
        let avg = scores.reduce(0, +) / scores.count

        // Simple weighted average (more recent = more weight)
        var weightedSum = 0
        var totalWeight = 0
        for (i, score) in scores.enumerated() {
            let weight = i + 1
            weightedSum += score * weight
            totalWeight += weight
        }

        return weightedSum / totalWeight
    }

    /// Generate personalized recommendations
    private func generateRecommendations(for record: SleepRecord) -> [String] {
        var recommendations: [String] = []

        // Sleep debt recommendation
        let debt = calculateSleepDebt(for: record)
        if debt > 60 {
            recommendations.append("You're \(debt) minutes behind on sleep. Try adding 20-minute naps this week to recover.")
        } else if debt > 30 {
            recommendations.append("Mild sleep debt. An extra 30 minutes tonight could help.")
        }

        // Deep sleep recommendation
        if record.deepSleepMinutes < 60 {
            recommendations.append("Your deep sleep was low. Avoid alcohol within 3 hours of bedtime — it's one of the biggest suppressors of deep sleep.")
        }

        // REM recommendation
        if record.remSleepMinutes < 60 {
            recommendations.append("Low REM sleep. Late-night screen time before bed may be interfering. Try reading instead.")
        }

        // Breathing recommendation
        if let spo2 = record.spo2Avg, spo2 < 95 {
            recommendations.append("Your blood oxygen dropped during sleep (avg \(Int(spo2))%). Consider sleeping on your side and consulting a doctor if this persists.")
        }

        // Caffeine/exercise correlation
        if let caffeine = record.caffeineMg, caffeine > 200 {
            recommendations.append("You had \(Int(caffeine))mg of caffeine today. For better sleep, try stopping caffeine by 2pm.")
        }

        if let exercise = record.exerciseMinutes, exercise > 30 {
            recommendations.append("Good: \(Int(exercise)) minutes of exercise today. Exercise consistently improves sleep quality over time.")
        }

        return recommendations
    }

    /// Generate weekly narrative summary
    func generateWeeklyNarrative() async -> WeeklySleepNarrative {
        let recent = Array(historicalRecords.suffix(7))
        guard !recent.isEmpty else {
            return WeeklySleepNarrative(
                startDate: Date(),
                endDate: Date(),
                averageScore: 0,
                totalNights: 0,
                nightsWith7HoursPlus: 0,
                bestNight: nil,
                worstNight: nil,
                trend: "stable",
                narrative: "No sleep data available."
            )
        }

        let avgScore = recent.map { $0.score }.reduce(0, +) / recent.count
        let nights7Plus = recent.filter { $0.totalDuration >= 7 * 3600 }.count

        let best = recent.max(by: { $0.score < $1.score })
        let worst = recent.min(by: { $0.score < $1.score })

        let sortedByDate = recent.sorted { $0.date < $1.date }
        let trend = await calculateWeeklyTrend()

        let narrative: String
        if avgScore >= 82 {
            narrative = "This was a great week of sleep. Your average score of \(avgScore) puts you in the top tier of sleepers. Keep doing what you're doing — consistency is the key."
        } else if avgScore >= 70 {
            narrative = "A solid week overall at \(avgScore) average. You're getting enough sleep on \(nights7Plus) out of \(recent.count) nights. A few small tweaks could push you into excellent territory."
        } else {
            narrative = "This week has been challenging for sleep (average \(avgScore)). Sleep quality often reflects what's happening in your life — stress, schedule changes, or lifestyle factors. Try to identify one thing you can improve."
        }

        return WeeklySleepNarrative(
            startDate: sortedByDate.first?.date ?? Date(),
            endDate: sortedByDate.last?.date ?? Date(),
            averageScore: avgScore,
            totalNights: recent.count,
            nightsWith7HoursPlus: nights7Plus,
            bestNight: best?.date,
            worstNight: worst?.date,
            trend: trend,
            narrative: narrative
        )
    }
}

extension SleepRecord {
    var totalMinutesFormatted: String {
        let minutes = Int(totalDuration / 60)
        return "\(minutes)m"
    }
}
