import SwiftUI
import Charts

struct SleepDebtView: View {
    @StateObject private var viewModel = SleepDebtViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                debtCard
                weeklyChart
                recoveryPlan
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Sleep Debt")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Track your weekly sleep and plan recovery")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Debt Card

    private var debtCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(viewModel.debtDescription)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(debtColor)
                }

                Spacer()

                debtIndicator
            }

            Divider()

            HStack {
                debtStat(title: "Slept", value: viewModel.totalSleptFormatted, icon: "bed.double.fill", color: .blue)
                Spacer()
                debtStat(title: "Optimal", value: viewModel.optimalFormatted, icon: "target", color: .green)
                Spacer()
                debtStat(title: "Debt", value: viewModel.debtFormatted, icon: "exclamationmark.triangle.fill", color: debtColor)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var debtIndicator: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: min(1.0, Double(viewModel.sleepQualityScore) / 100.0))
                .stroke(debtColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(viewModel.sleepQualityScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80, height: 80)
    }

    private func debtStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var debtColor: Color {
        if viewModel.sleepDebtSeconds > 3600 {
            return .red
        } else if viewModel.sleepDebtSeconds > 0 {
            return .orange
        } else if viewModel.sleepDebtSeconds < -3600 {
            return .blue // Overslept
        } else {
            return .green
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)

            if #available(macOS 13.0, *) {
                Chart(viewModel.dailyData) { day in
                    BarMark(
                        x: .value("Day", day.dayName),
                        y: .value("Hours", day.hoursSlept)
                    )
                    .foregroundStyle(day.hoursSlept >= 7 ? Color.green.gradient : Color.orange.gradient)

                    RuleMark(y: .value("Optimal", 8))
                        .foregroundStyle(Color.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                            }
                        }
                    }
                }
            } else {
                // Fallback for older macOS
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(viewModel.dailyData) { day in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(day.hoursSlept >= 7 ? Color.green : Color.orange)
                                .frame(width: 30, height: CGFloat(day.hoursSlept) * 20)

                            Text(day.dayName)
                                .font(.caption2)
                        }
                    }
                }
                .frame(height: 200)
            }

            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Met goal (7h+)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text("Below goal")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Rectangle()
                    .stroke(Color.blue, lineWidth: 1)
                    .frame(width: 20, height: 0)
                Text("Optimal (8h)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Recovery Plan

    private var recoveryPlan: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Plan")
                .font(.headline)

            if viewModel.sleepDebtSeconds > 3600 {
                recoverySuggestions
            } else if viewModel.sleepDebtSeconds < -3600 {
                oversleepWarning
            } else {
                healthySleepMessage
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var recoverySuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            suggestionRow(
                icon: "moon.zzz.fill",
                title: "Go to bed 30 min earlier",
                subtitle: "Tonight and for the next \(recoveryDays) nights"
            )

            suggestionRow(
                icon: "alarm.fill",
                title: "Maintain consistent wake time",
                subtitle: "Even on weekends to reset your rhythm"
            )

            suggestionRow(
                icon: "cup.and.saucer.fill",
                title: "Avoid caffeine after 2 PM",
                subtitle: "Helps achieve deeper sleep cycles"
            )

            suggestionRow(
                icon: "figure.walk",
                title: "Light exercise today",
                subtitle: "But not within 3 hours of bedtime"
            )

            if viewModel.sleepDebtSeconds > 7200 {
                suggestionRow(
                    icon: "calendar",
                    title: "Consider a recovery day",
                    subtitle: "An extra 1-2 hours of sleep can help close the gap"
                )
            }
        }
    }

    private var oversleepWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("You're sleeping more than needed")
                    .font(.headline)
            }

            Text("Oversleeping can leave you feeling equally tired. Try to keep a consistent 7-9 hour sleep schedule.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var healthySleepMessage: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Great job! You're meeting your sleep goals.")
                .font(.headline)
        }
    }

    private func suggestionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var recoveryDays: Int {
        let debtHours = viewModel.sleepDebtSeconds / 3600
        return max(1, Int(ceil(debtHours / 0.5))) // 30 min earlier per night
    }
}

// MARK: - ViewModel

@MainActor
class SleepDebtViewModel: ObservableObject {
    @Published var dailyData: [SleepDebtDayData] = []
    @Published var sleepDebtSeconds: TimeInterval = 0
    @Published var sleepQualityScore: Int = 70

    private let healthKitService = HealthKitService.shared
    private let optimalSleepPerNight: TimeInterval = 8 * 3600 // 8 hours

    var totalSleptFormatted: String {
        let hours = Int(absoluteSleptSeconds) / 3600
        let minutes = (Int(absoluteSleptSeconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var optimalFormatted: String {
        let hours = Int(absoluteOptimalSeconds) / 3600
        let minutes = (Int(absoluteOptimalSeconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var debtFormatted: String {
        let absDebt = abs(sleepDebtSeconds)
        let hours = Int(absDebt) / 3600
        let minutes = (Int(absDebt) % 3600) / 60
        let prefix = sleepDebtSeconds > 0 ? "-" : "+"
        return "\(prefix)\(hours)h \(minutes)m"
    }

    var debtDescription: String {
        if sleepDebtSeconds > 3600 {
            return "You need more sleep"
        } else if sleepDebtSeconds > 0 {
            return "Slightly under slept"
        } else if sleepDebtSeconds < -3600 {
            return "Oversleeping"
        } else {
            return "Well rested"
        }
    }

    private var absoluteSleptSeconds: TimeInterval {
        abs(sleepDebtSeconds).rounded()
    }

    private var absoluteOptimalSeconds: TimeInterval {
        (absoluteSleptSeconds + abs(sleepDebtSeconds)).rounded()
    }

    func loadData() async {
        do {
            let sleepHistory = try await healthKitService.getSleepHistory(days: 7)
            processSleepData(sleepHistory)
        } catch {
            // Use mock data if HealthKit fails
            generateMockData()
        }
    }

    private func processSleepData(_ sleepData: [HealthKitService.SleepData]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var dailyMap: [String: TimeInterval] = [:]

        for (index, data) in sleepData.prefix(7).enumerated() {
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            let dayKey = date.description
            dailyMap[dayKey] = data.totalSleep
        }

        dailyData = dailyMap.map { key, seconds in
            let date = ISO8601DateFormatter().date(from: key) ?? Date()
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let hours = seconds / 3600
            return SleepDebtDayData(dayName: dayName, hoursSlept: hours)
        }.sorted { day1, day2 in
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days.firstIndex(of: day1.dayName)! < days.firstIndex(of: day2.dayName)!
        }

        calculateDebt()
    }

    private func calculateDebt() {
        let totalSlept = dailyData.reduce(0) { $0 + $1.hoursSlept } * 3600
        let optimalTotal = Double(dailyData.count) * optimalSleepPerNight

        sleepDebtSeconds = totalSlept - optimalTotal

        // Calculate quality score
        let avgSleepHours = dailyData.isEmpty ? 0 : (totalSlept / 3600) / Double(dailyData.count)
        if avgSleepHours >= 7 && avgSleepHours <= 9 {
            sleepQualityScore = 90
        } else if avgSleepHours >= 6 && avgSleepHours <= 10 {
            sleepQualityScore = 70
        } else {
            sleepQualityScore = 50
        }
    }

    private func generateMockData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        dailyData = (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let hours = Double.random(in: 5...9)
            return SleepDebtDayData(dayName: dayName, hoursSlept: hours)
        }.sorted { day1, day2 in
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days.firstIndex(of: day1.dayName)! < days.firstIndex(of: day2.dayName)!
        }

        calculateDebt()
    }
}

// MARK: - Data Models

struct SleepDebtDayData: Identifiable {
    let id = UUID()
    let dayName: String
    let hoursSlept: Double
}

#Preview {
    SleepDebtView()
        .frame(width: 500, height: 700)
}
