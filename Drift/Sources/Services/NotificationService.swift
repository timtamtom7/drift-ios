import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    enum NotificationType: String, CaseIterable {
        case weeklyReportReady = "weekly_report_ready"
        case lowSleepWarning = "low_sleep_warning"
        case sleepDebtAlert = "sleep_debt_alert"
        case smartAlarmSuggestion = "smart_alarm_suggestion"
        case familyUpdate = "family_update"

        var title: String {
            switch self {
            case .weeklyReportReady: return "Weekly Report Ready"
            case .lowSleepWarning: return "Low Sleep Alert"
            case .sleepDebtAlert: return "Sleep Debt"
            case .smartAlarmSuggestion: return "Smart Wake Suggestion"
            case .familyUpdate: return "Family Sleep Update"
            }
        }
    }

    init() {
        checkAuthorizationStatus()
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAuthorized = status == .authorized || status == .provisional
            }
        }
    }

    // MARK: - Weekly Report Ready

    func scheduleWeeklyReportNotification(reportDate: Date) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Sleep Report Ready"
        content.body = "Your weekly sleep report is ready! See how your sleep evolved this week."
        content.sound = .default
        content.categoryIdentifier = NotificationType.weeklyReportReady.rawValue

        // Schedule for Sunday at 7 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.weeklyReportReady.rawValue,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule weekly report notification: \(error)")
        }
    }

    // MARK: - Low Sleep Warning

    func sendLowSleepWarning(sleepHours: Double) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()

        if sleepHours < 4 {
            content.title = "😴 You only slept \(String(format: "%.1f", sleepHours))h last night"
            content.body = "That's below 4 hours. Short sleep affects mood, focus, and immune function. Try to catch up tonight."
        } else if sleepHours < 6 {
            content.title = "😔 You only slept \(String(format: "%.1f", sleepHours))h"
            content.body = "That's under the recommended 7-9 hours. Your deep sleep may have been压缩. Consider an early night."
        } else {
            content.title = "📉 Slightly short sleep: \(String(format: "%.1f", sleepHours))h"
            content.body = "You got some rest, but a bit less than ideal. Your body can usually recover with one good night."
        }

        content.sound = .default
        content.categoryIdentifier = NotificationType.lowSleepWarning.rawValue

        let request = UNNotificationRequest(
            identifier: "\(NotificationType.lowSleepWarning.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send low sleep warning: \(error)")
        }
    }

    // MARK: - Sleep Debt Alert

    func sendSleepDebtAlert(debtHours: Double) async {
        guard isAuthorized, debtHours >= 1 else { return }

        let content = UNMutableNotificationContent()

        if debtHours >= 10 {
            content.title = "⚠️ Sleep debt: \(String(format: "%.0f", debtHours)) hours"
            content.body = "You're significantly sleep deprived. This affects decision-making and reaction time. Prioritize rest this weekend."
        } else if debtHours >= 5 {
            content.title = "😴 Sleep debt: \(String(format: "%.0f", debtHours)) hours"
            content.body = "You've built up notable sleep debt. An extra 1-2 hours per night this week can help you recover."
        } else {
            content.title = "📊 Sleep debt: \(String(format: "%.0f", debtHours)) hours"
            content.body = "Minor sleep debt accumulated. Try going to bed 30 minutes earlier to even things out."
        }

        content.sound = .default
        content.categoryIdentifier = NotificationType.sleepDebtAlert.rawValue

        let request = UNNotificationRequest(
            identifier: "\(NotificationType.sleepDebtAlert.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send sleep debt alert: \(error)")
        }
    }

    // MARK: - Smart Alarm Suggestion

    func sendSmartAlarmSuggestion(optimalWakeTime: Date) async {
        guard isAuthorized else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let content = UNMutableNotificationContent()
        content.title = "⏰ Set your smart alarm?"
        content.body = "Based on your sleep cycles, waking at \(formatter.string(from: optimalWakeTime)) would feel most refreshed."
        content.sound = .default
        content.categoryIdentifier = NotificationType.smartAlarmSuggestion.rawValue

        // Schedule for 9 PM the same day
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationType.smartAlarmSuggestion.rawValue,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule smart alarm suggestion: \(error)")
        }
    }

    // MARK: - Family Update

    func sendFamilySleepUpdate(memberName: String, score: Int) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "👨‍👩‍👧‍👦 \(memberName)'s sleep score: \(score)"
        content.body = "Your partner had a great night! See how your sleep compared in the Family tab."
        content.sound = .default
        content.categoryIdentifier = NotificationType.familyUpdate.rawValue

        let request = UNNotificationRequest(
            identifier: "\(NotificationType.familyUpdate.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send family update: \(error)")
        }
    }

    // MARK: - Cancel

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - Sleep Debt Calculation

    func calculateSleepDebt(records: [SleepRecord], targetHours: Double = 8.0) -> Double {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let recentRecords = records.filter { $0.date >= sevenDaysAgo }
        guard !recentRecords.isEmpty else { return 0 }

        let totalDeficit = recentRecords.reduce(0.0) { total, record in
            let deficit = targetHours - record.totalHours
            return total + max(0, deficit)
        }

        return totalDeficit
    }
}
