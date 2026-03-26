import SwiftUI

/// Dedicated view for tracking and improving sleep schedule consistency.
/// Shows bedtime targets, adherence history, chronotype, and social jetlag.
struct SleepScheduleView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var scheduleService = SleepScheduleService()
    @State private var showingBedtimePicker = false
    @State private var showingWakeTimePicker = false
    @State private var editingBedtime = false
    @State private var editingWakeTime = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Tonight's recommendation banner
                        if let rec = scheduleService.tonightRecommendation {
                            tonightRecommendationBanner(rec)
                        }

                        // Consistency score card
                        consistencyScoreCard

                        // Schedule targets
                        scheduleTargetsCard

                        // Chronotype card
                        chronotypeCard

                        // Social jetlag card
                        socialJetlagCard

                        // Weekly breakdown
                        weeklyBreakdownCard

                        // Adherence history
                        if !scheduleService.schedule.adherenceHistory.isEmpty {
                            adherenceHistoryCard
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sleep Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await scheduleService.analyzeRecords(healthKitService.weeklySleep)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Theme.deepSleep)
                    }
                }
            }
            .sheet(isPresented: $showingBedtimePicker) {
                TimePickerSheet(
                    title: "Target Bedtime",
                    selectedTime: Binding(
                        get: { scheduleService.schedule.targetBedtime ?? defaultBedtime() },
                        set: { scheduleService.setTargetBedtime($0) }
                    ),
                    onDismiss: { showingBedtimePicker = false }
                )
            }
            .sheet(isPresented: $showingWakeTimePicker) {
                TimePickerSheet(
                    title: "Target Wake Time",
                    selectedTime: Binding(
                        get: { scheduleService.schedule.targetWakeTime ?? defaultWakeTime() },
                        set: { scheduleService.setTargetWakeTime($0) }
                    ),
                    onDismiss: { showingWakeTimePicker = false }
                )
            }
        }
        .task {
            await scheduleService.analyzeRecords(healthKitService.weeklySleep)
        }
    }

    // MARK: - Tonight's Recommendation Banner

    private func tonightRecommendationBanner(_ rec: BedtimeRecommendation) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tonight's Bedtime")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(formatTime(rec.recommendedBedtime))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.deepSleep)
                        Text("Wind down in \(rec.timeUntilWindDown)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }

                    if rec.consistencyBonus > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.warningAccent)
                            Text("+\(rec.consistencyBonus) consistency bonus")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.warningAccent)
                        }
                    }
                }
            }

            Text(rec.reason)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let days = rec.daysUntilTargetMet, days > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.insightAccent)
                    Text("\(days) day\(days == 1 ? "" : "s") until hitting your 80% consistency target")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.insightAccent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Consistency Score Card

    private var consistencyScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Consistency Score")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Image(systemName: "clock.badge.checkmark.fill")
                    .foregroundColor(Theme.deepSleep)
                    .font(.caption)
            }

            HStack(alignment: .bottom, spacing: 16) {
                ConsistencyRing(score: scheduleService.schedule.weeklyConsistencyScore)
                    .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 6) {
                    Text(scoreLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text(scoreDescription)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(2)
                }

                Spacer()
            }

            if scheduleService.schedule.weeklyConsistencyScore > 0 {
                Divider()
                    .background(Theme.surface)

                HStack(spacing: 20) {
                    if let avgDev = averageDeviationForDisplay {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg Deviation")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                            Text(avgDev)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Target Set")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                        Text(scheduleService.schedule.isActive ? "Active" : "Not set")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(scheduleService.schedule.isActive ? Theme.insightAccent : Theme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var averageDeviationForDisplay: String? {
        let dev = scheduleService.schedule.averageBedtimeDeviation
        guard dev > 0 else { return nil }
        let hours = dev / 60
        let mins = dev % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    private var scoreLabel: String {
        switch scheduleService.schedule.weeklyConsistencyScore {
        case 80...100: return "Excellent"
        case 65..<80: return "Good"
        case 50..<65: return "Fair"
        case 25..<50: return "Needs Work"
        default: return scheduleService.schedule.weeklyConsistencyScore == 0 ? "No data" : "Poor"
        }
    }

    private var scoreDescription: String {
        switch scheduleService.schedule.weeklyConsistencyScore {
        case 80...100: return "Your sleep schedule is remarkably consistent. Great work!"
        case 65..<80: return "Good consistency. Minor deviations are normal."
        case 50..<65: return "Your schedule varies more than ideal. Small improvements help."
        case 25..<50: return "Inconsistent sleep times are hurting your rest quality."
        default: return scheduleService.schedule.weeklyConsistencyScore == 0
            ? "Set a target bedtime and wake time to start tracking."
            : "Your sleep times vary significantly. A routine would help."
        }
    }

    // MARK: - Schedule Targets Card

    private var scheduleTargetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Sleep Targets")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                // Bedtime target
                Button {
                    showingBedtimePicker = true
                } label: {
                    TargetTimeCard(
                        icon: "bed.double.fill",
                        label: "Bedtime",
                        time: scheduleService.schedule.targetBedtime,
                        color: Theme.deepSleep,
                        isEmpty: scheduleService.schedule.targetBedtime == nil
                    )
                }
                .buttonStyle(.plain)

                // Wake time target
                Button {
                    showingWakeTimePicker = true
                } label: {
                    TargetTimeCard(
                        icon: "sunrise.fill",
                        label: "Wake Time",
                        time: scheduleService.schedule.targetWakeTime,
                        color: Theme.warningAccent,
                        isEmpty: scheduleService.schedule.targetWakeTime == nil
                    )
                }
                .buttonStyle(.plain)
            }

            if scheduleService.schedule.targetBedtime != nil && scheduleService.schedule.targetWakeTime != nil {
                HStack {
                    Spacer()
                    let sleepDuration = calculateTargetSleepDuration()
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.lightSleep)
                        Text("Target sleep: \(sleepDuration)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .glassCard()
    }

    private func calculateTargetSleepDuration() -> String {
        guard let bed = scheduleService.schedule.targetBedtime,
              let wake = scheduleService.schedule.targetWakeTime else {
            return "—"
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: bed, to: wake)
        if components.hour ?? 0 < 0 {
            components.hour = (components.hour ?? 0) + 24
        }
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(hours)h"
    }

    // MARK: - Chronotype Card

    private var chronotypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Chronotype")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Text(scheduleService.schedule.chronotype.emoji)
                    .font(.system(size: 20))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scheduleService.schedule.chronotype.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(scheduleService.schedule.chronotype.description)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(2)
                }

                Spacer()

                ChronotypeIcon(type: scheduleService.schedule.chronotype)
            }

            Text("Chronotype is your natural preference for morning or evening activity, driven by your circadian rhythm. Understanding it helps tailor your sleep schedule.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .lineSpacing(1)
        }
        .padding()
        .glassCard()
    }

    // MARK: - Social Jetlag Card

    private var socialJetlagCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Social Jetlag")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                JetlagBadge(severity: scheduleService.schedule.socialJetlagSeverity)
            }

            if scheduleService.schedule.socialJetlagMinutes > 0 {
                HStack(spacing: 16) {
                    // Weekday schedule
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekday Avg")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)

                        if let bed = scheduleService.schedule.weekdayAverageBedtime,
                           let wake = scheduleService.schedule.weekdayAverageWakeTime {
                            Text(formatTime(bed))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.deepSleep)
                            Text("→ \(formatTime(wake))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        } else {
                            Text("—")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Divider()
                        .frame(height: 30)
                        .background(Theme.surface)

                    // Weekend schedule
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekend Avg")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)

                        if let bed = scheduleService.schedule.weekendAverageBedtime,
                           let wake = scheduleService.schedule.weekendAverageWakeTime {
                            Text(formatTime(bed))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.remSleep)
                            Text("→ \(formatTime(wake))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        } else {
                            Text("—")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Spacer()
                }
            }

            Text(scheduleService.schedule.socialJetlagSeverity.recommendation)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
        }
        .padding()
        .glassCard()
    }

    // MARK: - Weekly Breakdown Card

    private var weeklyBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Breakdown")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            let records = healthKitService.weeklySleep
            if records.isEmpty {
                HStack {
                    Spacer()
                    Text("No sleep data yet")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(records.sorted { $0.date > $1.date }.prefix(7)) { record in
                        WeeklyScheduleRow(record: record)
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Adherence History Card

    private var adherenceHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Adherence")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(scheduleService.schedule.adherenceHistory.suffix(7).reversed()) { entry in
                AdherenceRow(entry: entry)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func defaultBedtime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }

    private func defaultWakeTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Supporting Views

struct ConsistencyRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surface, lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("/100")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var ringGradient: LinearGradient {
        switch score {
        case 80...100:
            return LinearGradient(colors: [Theme.insightAccent, Theme.deepSleep], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 65..<80:
            return LinearGradient(colors: [Theme.deepSleep, Theme.lightSleep], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 50..<65:
            return LinearGradient(colors: [Theme.warningAccent, Theme.awake], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Theme.heartRate, Theme.heartRate.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct TargetTimeCard: View {
    let icon: String
    let label: String
    let time: Date?
    let color: Color
    let isEmpty: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEmpty ? Theme.textSecondary : color)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)

            if let time = time {
                Text(formatTime(time))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            } else {
                Text("Tap to set")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEmpty ? Theme.surface : color.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ChronotypeIcon: View {
    let type: SleepSchedule.Chronotype

    var body: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 52, height: 52)

            Image(systemName: iconName)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
        }
    }

    private var iconName: String {
        switch type {
        case .morningPerson: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .intermediate: return "scale.3d"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .morningPerson: return Theme.warningAccent
        case .nightOwl: return Theme.deepSleep
        case .intermediate: return Theme.lightSleep
        case .unknown: return Theme.textSecondary
        }
    }
}

struct JetlagBadge: View {
    let severity: SleepSchedule.SocialJetlagSeverity

    var body: some View {
        Text(severity.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch severity {
        case .none, .mild: return Theme.insightAccent
        case .moderate: return Theme.warningAccent
        case .significant, .severe: return Theme.heartRate
        }
    }
}

struct WeeklyScheduleRow: View {
    let record: SleepRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Text("\(formatTime(record.fellAsleepTime)) → \(formatTime(record.wokeUpTime))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.totalHoursFormatted)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Text("Score: \(record.score)")
                    .font(.system(size: 11))
                    .foregroundColor(scoreColor)
            }
        }
        .padding(.vertical, 4)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: record.date)
    }

    private var scoreColor: Color {
        Theme.scoreColor(for: record.score)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct AdherenceRow: View {
    let entry: ScheduleAdherenceEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 4) {
                    if let actual = entry.actualBedtime {
                        Text("Bed: \(formatTime(actual))")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.deepSleep)
                    }
                    if let actual = entry.actualWakeTime {
                        Text("Wake: \(formatTime(actual))")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.warningAccent)
                    }
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: entry.wasOnTime ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(entry.wasOnTime ? Theme.insightAccent : Theme.warningAccent)

                if entry.deviationMinutes > 0 {
                    Text(entry.deviationMinutes >= 60
                         ? "+\(entry.deviationMinutes / 60)h \(entry.deviationMinutes % 60)m"
                         : "+\(entry.deviationMinutes)m")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(entry.wasOnTime ? Theme.insightAccent : Theme.warningAccent)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    let title: String
    @Binding var selectedTime: Date
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorMultiply(Theme.deepSleep)
                        .frame(maxWidth: .infinity)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onDismiss()
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(Theme.deepSleep)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
