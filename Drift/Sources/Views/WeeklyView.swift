import SwiftUI

struct WeeklyView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedRecord: SleepRecord?
    private let insightService = AIInsightService()

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
                    VStack(spacing: 16) {
                        if healthKitService.weeklySleep.isEmpty {
                            emptyView
                        } else {
                            weekOverview
                            HRVTrendCard(records: healthKitService.weeklySleep)
                            weeklyCards
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRecord) { record in
                RecordDetailSheet(record: record)
            }
        }
        .task {
            await insightService.setHistoricalRecords(healthKitService.weeklySleep)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("No weekly data yet")
                .font(.headline)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, 100)
    }

    private var weekOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Summary")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                WeeklyStatBox(
                    title: "Avg Score",
                    value: "\(averageScore)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Theme.scoreColor(for: averageScore)
                )

                WeeklyStatBox(
                    title: "Avg Hours",
                    value: String(format: "%.1f", averageHours),
                    icon: "clock.fill",
                    color: Theme.lightSleep
                )

                WeeklyStatBox(
                    title: "Nights",
                    value: "\(healthKitService.weeklySleep.count)",
                    icon: "moon.stars.fill",
                    color: Theme.deepSleep
                )
            }
        }
    }

    private var weeklyCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Nights")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(healthKitService.weeklySleep) { record in
                WeeklyCard(record: record) {
                    selectedRecord = record
                }
            }
        }
    }

    private var averageScore: Int {
        guard !healthKitService.weeklySleep.isEmpty else { return 0 }
        return healthKitService.weeklySleep.map { $0.score }.reduce(0, +) / healthKitService.weeklySleep.count
    }

    private var averageHours: Double {
        guard !healthKitService.weeklySleep.isEmpty else { return 0 }
        return healthKitService.weeklySleep.map { $0.totalDuration / 3600 }.reduce(0, +) / Double(healthKitService.weeklySleep.count)
    }
}

struct WeeklyStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(Theme.textPrimary)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }
}

struct WeeklyCard: View {
    let record: SleepRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayOfWeek)
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(record.totalHoursFormatted)
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundColor(Theme.textPrimary)
                        Text("Total")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }

                    MiniScoreRing(score: record.score, size: 44)
                }
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: record.date)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: record.date)
    }
}

struct MiniScoreRing: View {
    let score: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surface, lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    Theme.scoreColor(for: score),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

/// Rich, full-screen detail view for a single sleep record.
/// Shown when tapping a day in History or a card in Weekly view.
struct RecordDetailSheet: View {
    let record: SleepRecord
    @Environment(\.dismiss) private var dismiss
    private let insightService = AIInsightService()

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
                    VStack(spacing: 24) {
                        // Score header
                        scoreHeaderSection

                        // Time details
                        timeDetailsSection

                        // Sleep stages
                        sleepStagesSection

                        // Vitals grid
                        vitalsSection

                        // Lifestyle factors
                        lifestyleSection

                        // Night quality summary
                        qualitySummarySection

                        // AI Insight for this night
                        if let insight = generateNightInsight() {
                            nightInsightSection(insight)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.deepSleep)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sleep details for \(formattedDate)")
    }

    // MARK: - Score Header

    private var scoreHeaderSection: some View {
        VStack(spacing: 16) {
            SleepScoreRing(score: record.score)
                .frame(height: 160)

            VStack(spacing: 4) {
                Text(scoreGrade)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.scoreColor(for: record.score))

                Text(scoreReason)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .glassCard()
    }

    private var scoreGrade: String {
        switch record.score {
        case 85...100: return "Excellent Night"
        case 70..<85: return "Good Night"
        case 55..<70: return "Fair Night"
        case 40..<55: return "Poor Night"
        default: return "Restless Night"
        }
    }

    private var scoreReason: String {
        if record.awakeMinutes > 60 {
            return "Multiple awakenings kept your score down"
        } else if record.totalHours < 6 {
            return "Not enough sleep duration tonight"
        } else if record.deepSleepMinutes < 60 {
            return "Your deep sleep was shorter than ideal"
        } else if record.remSleepMinutes < 60 {
            return "REM sleep was below optimal levels"
        } else {
            return "Well balanced sleep architecture tonight"
        }
    }

    // MARK: - Time Details

    private var timeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Times")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                TimeDetailCell(
                    icon: "bed.double.fill",
                    label: "Bedtime",
                    time: formatTime(record.fellAsleepTime),
                    color: Theme.deepSleep
                )

                TimeDetailCell(
                    icon: "sunrise.fill",
                    label: "Wake Time",
                    time: formatTime(record.wokeUpTime),
                    color: Theme.warningAccent
                )

                TimeDetailCell(
                    icon: "clock.fill",
                    label: "Duration",
                    time: record.totalHoursFormatted,
                    color: Theme.lightSleep
                )
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Sleep Stages

    private var sleepStagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Architecture")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            SleepStagesBar(stages: record.stages)
                .frame(height: 80)

            // Stage breakdown
            HStack(spacing: 8) {
                StageDetailPill(
                    label: "Deep",
                    minutes: record.deepSleepMinutes,
                    percentage: percentageFor(record.deepSleepMinutes),
                    color: Theme.deepSleep
                )
                StageDetailPill(
                    label: "REM",
                    minutes: record.remSleepMinutes,
                    percentage: percentageFor(record.remSleepMinutes),
                    color: Theme.remSleep
                )
                StageDetailPill(
                    label: "Light",
                    minutes: record.lightSleepMinutes,
                    percentage: percentageFor(record.lightSleepMinutes),
                    color: Theme.lightSleep
                )
                StageDetailPill(
                    label: "Awake",
                    minutes: record.awakeMinutes,
                    percentage: percentageFor(record.awakeMinutes),
                    color: Theme.awake
                )
            }
        }
        .padding()
        .glassCard()
    }

    private func percentageFor(_ minutes: Int) -> Int {
        guard record.totalMinutes > 0 else { return 0 }
        return Int(Double(minutes) / Double(record.totalMinutes) * 100)
    }

    // MARK: - Vitals

    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Vitals")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let hrMin = record.heartRateMin {
                    VitalPill(
                        icon: "heart.fill",
                        title: "Min HR",
                        value: "\(hrMin)",
                        unit: "bpm",
                        color: Theme.heartRate,
                        isGood: hrMin < 55,
                        goodLabel: "Low (good)"
                    )
                }

                if let hrMax = record.heartRateMax {
                    VitalPill(
                        icon: "heart.fill",
                        title: "Max HR",
                        value: "\(hrMax)",
                        unit: "bpm",
                        color: Theme.heartRate,
                        isGood: nil,
                        goodLabel: nil
                    )
                }

                if let hrAvg = record.heartRateAvg {
                    VitalPill(
                        icon: "waveform.path.ecg",
                        title: "Avg HR",
                        value: "\(hrAvg)",
                        unit: "bpm",
                        color: Theme.heartRate,
                        isGood: hrAvg < 65,
                        goodLabel: hrAvg < 65 ? "Resting (good)" : nil
                    )
                }

                if let hrv = record.hrvAvg {
                    VitalPill(
                        icon: "heart.circle.fill",
                        title: "HRV",
                        value: String(format: "%.0f", hrv),
                        unit: "ms",
                        color: Theme.insightAccent,
                        isGood: hrv > 40,
                        goodLabel: hrv > 40 ? "Good recovery" : "Below typical"
                    )
                }

                if let spo2 = record.spo2Avg {
                    VitalPill(
                        icon: "lungs.fill",
                        title: "SpO₂",
                        value: String(format: "%.0f", spo2),
                        unit: "%",
                        color: Theme.insightAccent,
                        isGood: spo2 >= 95,
                        goodLabel: spo2 >= 95 ? "Normal range" : "Below normal"
                    )
                }

                if let resp = record.respiratoryRateAvg {
                    VitalPill(
                        icon: "wind",
                        title: "Resp Rate",
                        value: String(format: "%.1f", resp),
                        unit: "brpm",
                        color: Theme.deepSleep,
                        isGood: resp >= 12 && resp <= 20,
                        goodLabel: (resp >= 12 && resp <= 20) ? "Normal" : "Outside typical"
                    )
                }
            }

            // Alert if SpO2 drops
            if let drops = record.spo2DropsBelow90, drops > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.warningAccent)
                        .font(.caption)
                    Text("\(drops) SpO₂ drop\(drops == 1 ? "" : "s") below 90% detected")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.warningAccent)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Lifestyle Factors

    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifestyle Factors")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let caffeine = record.caffeineMg {
                    LifestylePill(
                        icon: "cup.and.saucer.fill",
                        title: "Caffeine",
                        value: String(format: "%.0f mg", caffeine),
                        color: caffeineColor(caffeine),
                        note: caffeineNote(caffeine)
                    )
                }

                if let exercise = record.exerciseMinutes {
                    LifestylePill(
                        icon: "figure.run",
                        title: "Exercise",
                        value: String(format: "%.0f min", exercise),
                        color: exercise > 30 ? Theme.insightAccent : Theme.warningAccent,
                        note: exercise > 30 ? "Good activity" : "Below target"
                    )
                }

                if let mindful = record.mindfulMinutes, mindful > 0 {
                    LifestylePill(
                        icon: "brain.head.profile",
                        title: "Mindfulness",
                        value: String(format: "%.0f min", mindful),
                        color: Theme.deepSleep,
                        note: mindful >= 10 ? "Good session" : "Short session"
                    )
                }
            }

            if record.caffeineMg == nil && record.exerciseMinutes == nil && record.mindfulMinutes == nil {
                Text("No lifestyle data available for this night. Keep your Apple Watch and health apps connected to track these factors.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
                    .lineSpacing(2)
            }
        }
        .padding()
        .glassCard()
    }

    private func caffeineColor(_ mg: Double) -> Color {
        if mg < 100 { return Theme.insightAccent }
        if mg < 200 { return Theme.warningAccent }
        return Theme.heartRate
    }

    private func caffeineNote(_ mg: Double) -> String {
        if mg < 100 { return "Low intake" }
        if mg < 200 { return "Moderate" }
        return "High — may affect sleep"
    }

    // MARK: - Quality Summary

    private var qualitySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality Summary")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 8) {
                QualityRow(
                    label: "Duration",
                    status: durationQuality,
                    detail: record.totalHoursFormatted
                )

                QualityRow(
                    label: "Deep Sleep",
                    status: deepSleepQuality,
                    detail: "\(record.deepSleepMinutes)m"
                )

                QualityRow(
                    label: "REM Sleep",
                    status: remSleepQuality,
                    detail: "\(record.remSleepMinutes)m"
                )

                QualityRow(
                    label: "Interruptions",
                    status: awakeQuality,
                    detail: "\(record.awakeMinutes)m awake"
                )

                if let hrv = record.hrvAvg {
                    QualityRow(
                        label: "Recovery (HRV)",
                        status: hrvQuality(hrv),
                        detail: String(format: "%.0f ms", hrv)
                    )
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var durationQuality: QualityStatus {
        let hours = record.totalHours
        if hours >= 7 && hours <= 9 { return .good }
        if hours >= 6 { return .fair }
        return .poor
    }

    private var deepSleepQuality: QualityStatus {
        let target = Double(record.totalMinutes) * 0.2
        if Double(record.deepSleepMinutes) >= target { return .good }
        if Double(record.deepSleepMinutes) >= target * 0.7 { return .fair }
        return .poor
    }

    private var remSleepQuality: QualityStatus {
        let target = Double(record.totalMinutes) * 0.25
        if Double(record.remSleepMinutes) >= target { return .good }
        if Double(record.remSleepMinutes) >= target * 0.7 { return .fair }
        return .poor
    }

    private var awakeQuality: QualityStatus {
        if record.awakeMinutes <= 20 { return .good }
        if record.awakeMinutes <= 45 { return .fair }
        return .poor
    }

    private func hrvQuality(_ hrv: Double) -> QualityStatus {
        if hrv > 50 { return .good }
        if hrv > 30 { return .fair }
        return .poor
    }

    // MARK: - Night Insight

    private func nightInsightSection(_ insight: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.insightAccent)
                Text("Night Insight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            Text(insight)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(3)
        }
        .padding()
        .glassCard()
    }

    private func generateNightInsight() -> String? {
        // Generate a contextual insight for this specific night
        var insights: [String] = []

        if record.awakeMinutes > 45 {
            insights.append("You had \(record.awakeMinutes) minutes of wake time during the night. This many interruptions can significantly reduce sleep quality.")
        }

        if record.deepSleepMinutes < 60 && record.totalHours > 5 {
            insights.append("Deep sleep was shorter than the recommended 1-2 hours. This is your body's most restorative phase — consider wind-down routines before bed.")
        }

        if let hrv = record.hrvAvg, hrv > 60 {
            insights.append("Your HRV of \(Int(hrv)) ms suggests excellent parasympathetic nervous system activity — your body recovered very well tonight.")
        } else if let hrv = record.hrvAvg, hrv < 30 {
            insights.append("HRV was lower than typical (\(Int(hrv)) ms). This may indicate elevated stress or incomplete recovery.")
        }

        if let caffeine = record.caffeineMg, caffeine > 200 {
            insights.append("\(Int(caffeine)) mg of caffeine detected. High caffeine intake close to bedtime can suppress deep sleep and REM.")
        }

        if record.totalHours >= 8 {
            insights.append("Great total sleep duration of \(record.totalHoursFormatted). You met the recommended 7-9 hour target.")
        }

        return insights.first
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: record.date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

enum QualityStatus {
    case good, fair, poor

    var color: Color {
        switch self {
        case .good: return Theme.insightAccent
        case .fair: return Theme.warningAccent
        case .poor: return Theme.heartRate
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .fair: return "minus.circle.fill"
        case .poor: return "exclamationmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

struct TimeDetailCell: View {
    let icon: String
    let label: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(time)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StageDetailPill: View {
    let label: String
    let minutes: Int
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(percentage)%")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)

            Text("\(minutes)m")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct VitalPill: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let isGood: Bool?
    let goodLabel: String?

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textSecondary)
            }

            if let goodLabel = goodLabel {
                Text(goodLabel)
                    .font(.system(size: 8))
                    .foregroundColor(isGood == true ? Theme.insightAccent : Theme.warningAccent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct LifestylePill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let note: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)

                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text(note)
                    .font(.system(size: 9))
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QualityRow: View {
    let label: String
    let status: QualityStatus
    let detail: String

    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .font(.system(size: 12))
                .foregroundColor(status.color)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Text(detail)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
