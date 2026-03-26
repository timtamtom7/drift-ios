import Foundation
import os.log

/// Service responsible for analyzing sleep patterns, computing consistency scores,
/// detecting chronotype, and providing bedtime recommendations.
@MainActor
class SleepScheduleService: ObservableObject {
    @Published var schedule: SleepSchedule
    @Published var tonightRecommendation: BedtimeRecommendation?
    @Published var isLoading = false

    private let logger = Logger(subsystem: "com.drift.sleep", category: "ScheduleService")
    private let userDefaultsKey = "sleepSchedule"
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    init() {
        self.schedule = SleepSchedule()
        loadSchedule()
    }

    // MARK: - Persistence

    private func loadSchedule() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(SleepSchedule.self, from: data) else {
            return
        }
        schedule = decoded
    }

    func saveSchedule() {
        guard let data = try? JSONEncoder().encode(schedule) else {
            logger.error("Failed to encode sleep schedule")
            return
        }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    // MARK: - Analysis

    /// Analyze records to build or update the sleep schedule
    func analyzeRecords(_ records: [SleepRecord]) async {
        guard records.count >= 3 else {
            logger.info("Not enough records (\(records.count)) to build schedule, need at least 3")
            return
        }

        isLoading = true
        defer { isLoading = false }

        logger.info("Analyzing \(records.count) sleep records for schedule")

        let calendar = Calendar.current

        // Separate weekday vs weekend records
        var weekdayBedtimes: [Date] = []
        var weekdayWakeTimes: [Date] = []
        var weekendBedtimes: [Date] = []
        var weekendWakeTimes: [Date] = []

        for record in records {
            let weekday = calendar.component(.weekday, from: record.date)
            let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday

            if record.fellAsleepTime.hour >= 18 || record.fellAsleepTime.hour < 6 {
                // Only count reasonable bedtimes (between 6pm and 6am)
                if isWeekend {
                    weekendBedtimes.append(record.fellAsleepTime)
                } else {
                    weekdayBedtimes.append(record.fellAsleepTime)
                }
            }

            if record.wokeUpTime.hour >= 4 && record.wokeUpTime.hour <= 12 {
                if isWeekend {
                    weekendWakeTimes.append(record.wokeUpTime)
                } else {
                    weekdayWakeTimes.append(record.wokeUpTime)
                }
            }
        }

        // Calculate averages
        let avgWeekdayBedtime = averageTime(from: weekdayBedtimes)
        let avgWeekdayWakeTime = averageTime(from: weekdayWakeTimes)
        let avgWeekendBedtime = averageTime(from: weekendBedtimes)
        let avgWeekendWakeTime = averageTime(from: weekendWakeTimes)

        // Calculate social jetlag (difference between weekday and weekend midpoints)
        var jetlagMinutes = 0
        if let wBedtime = avgWeekdayBedtime, let wWakeTime = avgWeekdayWakeTime,
           let weBedtime = avgWeekendBedtime, let weWakeTime = avgWeekendWakeTime {
            let weekdayMidpoint = midpoint(wakeTime: wWakeTime, bedTime: wBedtime)
            let weekendMidpoint = midpoint(wakeTime: weWakeTime, bedTime: weBedtime)
            jetlagMinutes = abs(minutesBetween(weekdayMidpoint, weekendMidpoint))
        }

        // Calculate consistency score
        let consistencyScore = calculateConsistencyScore(records: records)

        // Determine chronotype based on average sleep midpoint
        let chronotype = determineChronotype(
            weekdayBedtime: avgWeekdayBedtime,
            weekdayWakeTime: avgWeekdayWakeTime
        )

        // Update schedule
        schedule.weekdayAverageBedtime = avgWeekdayBedtime
        schedule.weekdayAverageWakeTime = avgWeekdayWakeTime
        schedule.weekendAverageBedtime = avgWeekendBedtime
        schedule.weekendAverageWakeTime = avgWeekendWakeTime
        schedule.socialJetlagMinutes = jetlagMinutes
        schedule.weeklyConsistencyScore = consistencyScore
        schedule.chronotype = chronotype
        schedule.lastUpdated = Date()

        // If no target set yet, suggest one based on averages
        if schedule.targetBedtime == nil, let targetBed = avgWeekdayBedtime {
            schedule.targetBedtime = targetBed
        }
        if schedule.targetWakeTime == nil, let targetWake = avgWeekdayWakeTime {
            schedule.targetWakeTime = targetWake
        }

        // Generate tonight's recommendation
        tonightRecommendation = generateTonightRecommendation(records: records)

        saveSchedule()

        logger.info("Schedule analysis complete. Consistency: \(consistencyScore), Jetlag: \(jetlagMinutes)min, Chronotype: \(chronotype.rawValue)")
    }

    // MARK: - Target Setting

    func setTargetBedtime(_ time: Date) {
        schedule.targetBedtime = time
        schedule.isActive = true
        saveSchedule()
        logger.info("Target bedtime set to \(Self.dateFormatter.string(from: time))")
    }

    func setTargetWakeTime(_ time: Date) {
        schedule.targetWakeTime = time
        schedule.isActive = true
        saveSchedule()
        logger.info("Target wake time set to \(Self.dateFormatter.string(from: time))")
    }

    func setWindDownMinutes(_ minutes: Int) {
        schedule.windDownMinutesBefore = minutes
        saveSchedule()
    }

    func deactivateSchedule() {
        schedule.isActive = false
        saveSchedule()
    }

    // MARK: - Private Helpers

    /// Compute the average time-of-day from a list of dates (ignores the date, only uses time components)
    private func averageTime(from dates: [Date]) -> Date? {
        guard !dates.isEmpty else { return nil }

        let calendar = Calendar.current

        // Convert each date to minutes since midnight
        let minutesArray = dates.map { date -> Int in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }

        let averageMinutes = Double(minutesArray.reduce(0, +)) / Double(minutesArray.count)

        // Build a date using today's date with the average time
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = Int(averageMinutes / 60)
        components.minute = Int(averageMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components)
    }

    /// Compute the midpoint between a wake time and bedtime (in clock hours)
    private func midpoint(wakeTime: Date, bedTime: Date) -> Date {
        let calendar = Calendar.current
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedTime)

        let wakeMinutes = (wakeComponents.hour ?? 0) * 60 + (wakeComponents.minute ?? 0)
        let bedMinutes = (bedComponents.hour ?? 0) * 60 + (bedComponents.minute ?? 0)

        // Handle crossing midnight
        let adjustedBedMinutes = bedMinutes < wakeMinutes ? bedMinutes + 24 * 60 : bedMinutes
        let midMinutes = (wakeMinutes + adjustedBedMinutes) / 2

        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        let midHour = (midMinutes / 60) % 24
        components.hour = midHour
        components.minute = midMinutes % 60

        return calendar.date(from: components) ?? Date()
    }

    /// Minutes between two dates (ignores day,只看time)
    private func minutesBetween(_ a: Date, _ b: Date) -> Int {
        let calendar = Calendar.current
        let aComps = calendar.dateComponents([.hour, .minute], from: a)
        let bComps = calendar.dateComponents([.hour, .minute], from: b)
        let aMinutes = (aComps.hour ?? 0) * 60 + (aComps.minute ?? 0)
        let bMinutes = (bComps.hour ?? 0) * 60 + (bComps.minute ?? 0)
        var diff = bMinutes - aMinutes
        if diff < -12 * 60 { diff += 24 * 60 } // Handle overnight crossing
        if diff > 12 * 60 { diff -= 24 * 60 }
        return abs(diff)
    }

    /// Calculate consistency score (0-100) based on how much bedtime/wake time varies
    private func calculateConsistencyScore(records: [SleepRecord]) -> Int {
        let calendar = Calendar.current

        // Group bedtimes and wake times by weekday
        var bedtimeVariances: [Int: [Int]] = [:] // weekday -> [minutes from midnight]
        var wakeVariances: [Int: [Int]] = [:]

        for record in records {
            let weekday = calendar.component(.weekday, from: record.date)
            let bedHour = record.fellAsleepTime.hour
            let bedMinute = record.fellAsleepTime.minute
            let wakeHour = record.wokeUpTime.hour
            let wakeMinute = record.wokeUpTime.minute

            // Skip obviously wrong data
            if bedHour >= 18 || bedHour < 4 {
                let bedMinutes = bedHour * 60 + bedMinute
                bedtimeVariances[weekday, default: []].append(bedMinutes)
            }
            if wakeHour >= 5 && wakeHour <= 12 {
                let wakeMinutes = wakeHour * 60 + wakeMinute
                wakeVariances[weekday, default: []].append(wakeMinutes)
            }
        }

        // Calculate standard deviation for each weekday
        var allVariances: [Int] = []
        for (_, bedtimes) in bedtimeVariances {
            if bedtimes.count >= 2 {
                allVariances.append(contentsOf: bedtimes)
            }
        }

        guard !allVariances.isEmpty else { return 50 }

        let mean = Double(allVariances.reduce(0, +)) / Double(allVariances.count)
        let variance = allVariances.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(allVariances.count)
        let stdDev = sqrt(variance)

        // Convert std dev to score (lower variance = higher score)
        // stdDev of 0 = 100, stdDev of 60min = 75, stdDev of 120+ = 0
        let score = max(0, min(100, Int(100 - (stdDev / 1.2))))
        return score
    }

    /// Determine chronotype based on average midpoint of sleep
    private func determineChronotype(weekdayBedtime: Date?, weekdayWakeTime: Date?) -> SleepSchedule.Chronotype {
        guard let bedtime = weekdayBedtime, let wakeTime = weekdayWakeTime else {
            return .unknown
        }

        let calendar = Calendar.current
        let bedH = calendar.component(.hour, from: bedtime)
        let bedM = calendar.component(.minute, from: bedtime)
        let wakeH = calendar.component(.hour, from: wakeTime)

        // Approximate midpoint of sleep
        let adjustedBed = (bedH < 12 ? bedH + 24 : bedH) * 60 + bedM
        let adjustedWake = wakeH * 60
        let midpoint = (adjustedBed + adjustedWake) / 2
        let midpointHour = Double(midpoint) / 60.0

        if midpointHour < 2.5 || midpointHour > 22.5 {
            return .nightOwl
        } else if midpointHour < 3.5 {
            return .intermediate
        } else {
            return .morningPerson
        }
    }

    /// Generate bedtime recommendation for tonight
    private func generateTonightRecommendation(records: [SleepRecord]) -> BedtimeRecommendation? {
        guard let targetBedtime = schedule.targetBedtime else {
            // No target set — suggest based on historical average
            let recentBedtimes = records.sorted { $0.date > $1.date }
                .prefix(7)
                .map { $0.fellAsleepTime }

            guard let avgBedtime = averageTime(from: recentBedtimes.map { $0 }) else {
                return nil
            }

            let windDown = Calendar.current.date(
                byAdding: .minute,
                value: -schedule.windDownMinutesBefore,
                to: avgBedtime
            ) ?? avgBedtime

            let daysOnTrack = recentBedtimes.count // simplified
            let bonus = daysOnTrack >= 5 ? 10 : (daysOnTrack >= 3 ? 5 : 0)

            return BedtimeRecommendation(
                recommendedBedtime: avgBedtime,
                windDownTime: windDown,
                reason: "Based on your recent average bedtime",
                consistencyBonus: bonus,
                daysUntilTargetMet: nil
            )
        }

        // Calculate adherence over the past week
        let recentRecords = records.sorted { $0.date > $1.date }
            .prefix(7)
        let onTimeCount = recentRecords.filter { record in
            guard let scheduled = schedule.targetBedtime else { return false }
            let deviation = abs(minutesBetween(record.fellAsleepTime, scheduled))
            return deviation <= 30
        }.count

        let consistencyBonus = recentRecords.isEmpty ? 0 : (onTimeCount * 10 / max(1, recentRecords.count))

        let windDown = Calendar.current.date(
            byAdding: .minute,
            value: -schedule.windDownMinutesBefore,
            to: targetBedtime
        ) ?? targetBedtime

        // Calculate days until hitting consistency target
        let currentScore = schedule.weeklyConsistencyScore
        let targetScore = 80
        let daysNeeded = currentScore >= targetScore ? 0 : ((targetScore - currentScore) / 15) + 1

        return BedtimeRecommendation(
            recommendedBedtime: targetBedtime,
            windDownTime: windDown,
            reason: "Tonight's scheduled bedtime based on your target",
            consistencyBonus: consistencyBonus,
            daysUntilTargetMet: daysNeeded
        )
    }
}

// MARK: - Date Extension

private extension Date {
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
}
