import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var allRecords: [SleepRecord] = []
    @State private var selectedRecord: SleepRecord?
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

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
                        calendarHeader
                        calendarGrid
                        legendView
                    }
                    .padding()
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRecord) { record in
                RecordDetailSheet(record: record)
            }
        }
        .task {
            allRecords = healthKitService.weeklySleep
        }
    }

    private var calendarHeader: some View {
        HStack {
            Button {
                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Text(monthYearString)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button {
                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal)
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            weekdayHeader

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth, id: \.self) { day in
                    if let day = day {
                        DayCell(
                            date: day,
                            record: recordForDay(day),
                            isToday: calendar.isDateInToday(day)
                        ) {
                            if let record = recordForDay(day) {
                                selectedRecord = record
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            Text("Score:")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 4) {
                Circle().fill(Theme.heartRate).frame(width: 12, height: 12)
                Text("<60")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: 4) {
                Circle().fill(Theme.warningAccent).frame(width: 12, height: 12)
                Text("60-79")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: 4) {
                Circle().fill(Theme.insightAccent).frame(width: 12, height: 12)
                Text("80+")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func recordForDay(_ day: Date) -> SleepRecord? {
        let startOfDay = calendar.startOfDay(for: day)
        return allRecords.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }
}

struct DayCell: View {
    let date: Date
    let record: SleepRecord?
    let isToday: Bool
    let onTap: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let record = record {
                    Circle()
                        .fill(scoreColor(for: record.score).opacity(0.8))
                        .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .stroke(Theme.surface, lineWidth: 1)
                        .frame(width: 36, height: 36)
                }

                if isToday {
                    Circle()
                        .stroke(Theme.textPrimary, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                Text("\(dayNumber)")
                    .font(.system(size: 13, weight: record != nil ? .semibold : .regular))
                    .foregroundColor(record != nil ? .white : Theme.textSecondary.opacity(0.5))
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }

    private func scoreColor(for score: Int) -> Color {
        if score >= 80 { return Theme.insightAccent }
        if score >= 60 { return Theme.warningAccent }
        return Theme.heartRate
    }
}
