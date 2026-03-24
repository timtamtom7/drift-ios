import Foundation
import UserNotifications
import AVFoundation
import HealthKit
import UIKit

// MARK: - Smart Wake Alarm Model

struct SmartWakeAlarm: Identifiable, Codable {
    let id: UUID
    var targetTime: Date
    var windowMinutes: Int // e.g., 30 means 7:00-7:30am
    var isEnabled: Bool
    var label: String
    var soundName: String
    var vibrate: Bool
    var days: [Weekday]

    enum Weekday: Int, Codable, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var shortName: String {
            switch self {
            case .sunday: return "S"
            case .monday: return "M"
            case .tuesday: return "T"
            case .wednesday: return "W"
            case .thursday: return "T"
            case .friday: return "F"
            case .saturday: return "S"
            }
        }

        var fullName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }

    var windowEndTime: Date {
        Calendar.current.date(byAdding: .minute, value: windowMinutes, to: targetTime) ?? targetTime
    }

    init(
        id: UUID = UUID(),
        targetTime: Date,
        windowMinutes: Int = 30,
        isEnabled: Bool = true,
        label: String = "Wake up",
        soundName: String = "gentle_rise",
        vibrate: Bool = true,
        days: [Weekday] = Weekday.allCases
    ) {
        self.id = id
        self.targetTime = targetTime
        self.windowMinutes = windowMinutes
        self.isEnabled = isEnabled
        self.label = label
        self.soundName = soundName
        self.vibrate = vibrate
        self.days = days
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: targetTime)
    }

    var formattedWindow: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formattedTime) – \(formatter.string(from: windowEndTime))"
    }
}

// MARK: - Sleep Stage for Wake Detection

struct SleepPhaseForWake {
    let type: SleepStageType
    let startDate: Date
    let endDate: Date

    var isLightSleep: Bool {
        type == .light || type == .awake
    }
}

// MARK: - Smart Wake Service

@MainActor
class SmartWakeService: ObservableObject {
    @Published var alarms: [SmartWakeAlarm] = []
    @Published var isMonitoring = false
    @Published var activeAlarm: SmartWakeAlarm?
    @Published var lightSleepDetected = false

    private var monitoringTask: Task<Void, Never>?
    private var audioPlayer: AVAudioPlayer?
    private let healthStore = HKHealthStore()

    private let alarmsKey = "smartWakeAlarms"

    init() {
        loadAlarms()
    }

    // MARK: - Alarm Management

    func addAlarm(_ alarm: SmartWakeAlarm) {
        alarms.append(alarm)
        saveAlarms()
    }

    func updateAlarm(_ alarm: SmartWakeAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
        }
    }

    func deleteAlarm(_ alarm: SmartWakeAlarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }

    func toggleAlarm(_ alarm: SmartWakeAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
        }
    }

    // MARK: - Persistence

    private func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: alarmsKey)
        }
    }

    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([SmartWakeAlarm].self, from: data) {
            alarms = decoded
        }
    }

    // MARK: - Smart Wake Monitoring

    func startMonitoring(for alarm: SmartWakeAlarm) {
        stopMonitoring()
        activeAlarm = alarm
        isMonitoring = true
        lightSleepDetected = false

        monitoringTask = Task {
            await findLightSleepWindow(for: alarm)
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        activeAlarm = nil
        lightSleepDetected = false
        stopSound()
    }

    private func findLightSleepWindow(for alarm: SmartWakeAlarm) async {
        let calendar = Calendar.current
        let now = Date()

        // Calculate the window start time (e.g., 7:00am)
        let alarmHour = calendar.component(.hour, from: alarm.targetTime)
        let alarmMinute = calendar.component(.minute, from: alarm.targetTime)

        // Get today's alarm time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = alarmHour
        components.minute = alarmMinute
        components.second = 0

        guard let windowStart = calendar.date(from: components) else { return }
        let windowEnd = calendar.date(byAdding: .minute, value: alarm.windowMinutes, to: windowStart) ?? windowStart

        // If the alarm time has already passed today, schedule for tomorrow
        let effectiveWindowStart: Date
        let effectiveWindowEnd: Date

        if windowStart <= now {
            effectiveWindowStart = calendar.date(byAdding: .day, value: 1, to: windowStart) ?? windowStart
            effectiveWindowEnd = calendar.date(byAdding: .day, value: 1, to: windowEnd) ?? windowEnd
        } else {
            effectiveWindowStart = windowStart
            effectiveWindowEnd = windowEnd
        }

        // Poll for light sleep every 5 minutes during the window
        var currentCheck = effectiveWindowStart

        while !Task.isCancelled && isMonitoring {
            let currentTime = Date()

            if currentTime >= effectiveWindowEnd {
                // Window closed - trigger alarm at end time
                if !Task.isCancelled && isMonitoring {
                    await triggerWake(for: alarm, wasInLightSleep: lightSleepDetected)
                }
                break
            }

            if currentTime >= effectiveWindowStart {
                // Check if in light sleep
                let inLightSleep = await checkForLightSleep(during: currentTime)
                if inLightSleep {
                    lightSleepDetected = true
                    await triggerWake(for: alarm, wasInLightSleep: true)
                    break
                }
            }

            // Wait 5 minutes before next check
            try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
        }
    }

    private func checkForLightSleep(during date: Date) async -> Bool {
        // This is a simplified check - in a real app, you'd use the
        // Apple Watch's real-time sleep stage data via HealthKit
        // For now, we'll use a probabilistic approach based on sleep cycles

        let calendar = Calendar.current
        let startOfSleep = calendar.date(byAdding: .hour, value: -8, to: date) ?? date

        do {
            guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
                return false
            }

            let predicate = HKQuery.predicateForSamples(withStart: startOfSleep, end: date, options: .strictStartDate)

            let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
                healthStore.execute(query)
            }

            // Check the most recent sleep sample
            guard let latestSample = samples.first else { return false }

            // Light sleep or awake = good time to wake
            let lightSleepTypes: [Int] = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.awake.rawValue
            ]

            return lightSleepTypes.contains(latestSample.value)
        } catch {
            print("Failed to check sleep stage: \(error)")
            return false
        }
    }

    private func triggerWake(for alarm: SmartWakeAlarm, wasInLightSleep: Bool) async {
        if alarm.vibrate {
            triggerVibration()
        }

        if wasInLightSleep {
            playGentleSound(alarm.soundName)
        } else {
            playGentleSound(alarm.soundName)
        }

        // Post notification
        await sendWakeNotification(for: alarm, wasInLightSleep: wasInLightSleep)

        isMonitoring = false
    }

    private func triggerVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func playGentleSound(_ soundName: String) {
        // In a real app, you'd load a sound file from the bundle
        // For now, we use the system sound as a placeholder
        // AudioServicesPlaySystemSound(1007) // Gentle sound
    }

    private func sendWakeNotification(for alarm: SmartWakeAlarm, wasInLightSleep: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = alarm.label

        if wasInLightSleep {
            content.body = "Woke you during light sleep. You should feel more refreshed!"
        } else {
            content.body = "Alarm time! Window closed."
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "smartwake-\(alarm.id.uuidString)",
            content: content,
            trigger: nil // immediate
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Next Alarm

    func nextAlarm() -> SmartWakeAlarm? {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)

        return alarms
            .filter { $0.isEnabled }
            .compactMap { alarm -> (alarm: SmartWakeAlarm, date: Date)? in
                // Find the next occurrence of this alarm
                let alarmWeekday = calendar.component(.weekday, from: alarm.targetTime)

                var daysToAdd = alarmWeekday - weekday
                if daysToAdd < 0 { daysToAdd += 7 }
                if daysToAdd == 0 {
                    // Check if the alarm time is still in the future today
                    let alarmTimeToday = alarm.targetTime
                    if alarmTimeToday <= now {
                        daysToAdd = 7
                    }
                }

                guard let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                    return nil
                }

                return (alarm, nextDate)
            }
            .sorted { $0.date < $1.date }
            .first?.alarm
    }
}
