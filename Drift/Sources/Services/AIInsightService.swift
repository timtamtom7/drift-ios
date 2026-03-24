import Foundation
import NaturalLanguage

actor AIInsightService {
    private var historicalRecords: [SleepRecord] = []

    func setHistoricalRecords(_ records: [SleepRecord]) {
        self.historicalRecords = records
    }

    func generateInsight(for record: SleepRecord) async -> SleepInsight {
        let deepAvg = historicalRecords.isEmpty ? record.deepSleepMinutes :
            historicalRecords.map { $0.deepSleepMinutes }.reduce(0, +) / historicalRecords.count

        let remAvg = historicalRecords.isEmpty ? record.remSleepMinutes :
            historicalRecords.filter { !$0.stages.isEmpty }.map { $0.remSleepMinutes }.reduce(0, +) / max(1, historicalRecords.filter { !$0.stages.isEmpty }.count)

        var insights: [String] = []
        var isPositive = true

        // Deep sleep analysis
        let deepDiff = record.deepSleepMinutes - deepAvg
        if abs(deepDiff) <= 5 {
            // Consistent deep sleep
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
            // Already have a positive insight, add context
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

        let finalText = insights.first ?? "A quiet night. Your sleep was consistent and steady."
        return SleepInsight(text: finalText, isPositive: isPositive)
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

        return insights
    }
}

extension SleepRecord {
    var totalMinutesFormatted: String {
        let minutes = Int(totalDuration / 60)
        return "\(minutes)m"
    }
}
