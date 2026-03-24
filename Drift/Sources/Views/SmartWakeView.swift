import SwiftUI

struct SmartWakeView: View {
    @EnvironmentObject var smartWakeService: SmartWakeService
    @State private var showingAddAlarm = false
    @State private var selectedAlarm: SmartWakeAlarm?

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
                        if smartWakeService.alarms.isEmpty {
                            emptyStateView
                        } else {
                            activeAlarmCard
                            alarmsList
                        }

                        howItWorksCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Smart Wake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.deepSleep)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                SmartWakeSettingsView(alarm: nil) { newAlarm in
                    smartWakeService.addAlarm(newAlarm)
                }
            }
            .sheet(item: $selectedAlarm) { alarm in
                SmartWakeSettingsView(alarm: alarm) { updatedAlarm in
                    smartWakeService.updateAlarm(updatedAlarm)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "alarm.watch")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.deepSleep, Theme.remSleep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Smart Wake")
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)

                Text("Set a wake window and wake up during light sleep for a more refreshing morning.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Button {
                showingAddAlarm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Smart Alarm")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Theme.deepSleep, Theme.remSleep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
        }
    }

    private var activeAlarmCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Alarm")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                if let nextAlarm = smartWakeService.nextAlarm() {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Theme.insightAccent)
                            .frame(width: 6, height: 6)
                        Text("In \(timeUntil(nextAlarm))")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.insightAccent)
                    }
                }
            }

            if let nextAlarm = smartWakeService.nextAlarm() {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextAlarm.formattedTime)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        Text(nextAlarm.label)
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)

                        Text("Window: \(nextAlarm.formattedWindow)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Button {
                            smartWakeService.toggleAlarm(nextAlarm)
                        } label: {
                            Image(systemName: nextAlarm.isEnabled ? "bell.fill" : "bell.slash.fill")
                                .font(.title2)
                                .foregroundColor(nextAlarm.isEnabled ? Theme.warningAccent : Theme.textSecondary)
                        }

                        Button {
                            smartWakeService.startMonitoring(for: nextAlarm)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text("Test")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.deepSleep)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Weekday selector
                HStack(spacing: 6) {
                    ForEach(SmartWakeAlarm.Weekday.allCases, id: \.self) { day in
                        let isSelected = nextAlarm.days.contains(day)
                        Text(day.shortName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Theme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(isSelected ? Theme.deepSleep : Theme.surface)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var alarmsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Alarms")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(smartWakeService.alarms) { alarm in
                SmartAlarmRow(alarm: alarm) {
                    selectedAlarm = alarm
                } onToggle: {
                    smartWakeService.toggleAlarm(alarm)
                } onDelete: {
                    smartWakeService.deleteAlarm(alarm)
                }
            }
        }
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.deepSleep)
                Text("How Smart Wake Works")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            VStack(alignment: .leading, spacing: 8) {
                HowItWorksStep(
                    number: 1,
                    title: "Set a wake window",
                    description: "Choose a target wake time (e.g., 7:00am) and a window (e.g., 30 minutes)"
                )

                HowItWorksStep(
                    number: 2,
                    title: "Sleep as usual",
                    description: "Wear your Apple Watch to bed — Drift monitors your sleep stages"
                )

                HowItWorksStep(
                    number: 3,
                    title: "Wake at the right moment",
                    description: "When you're in light sleep within your window, Drift gently wakes you with vibration and sound"
                )
            }
        }
        .padding()
        .glassCard()
    }

    private func timeUntil(_ alarm: SmartWakeAlarm) -> String {
        let calendar = Calendar.current
        let now = Date()
        let targetTime = alarm.targetTime

        // If it's past the alarm time today, calculate for tomorrow
        var effectiveDate = targetTime
        if targetTime <= now {
            effectiveDate = calendar.date(byAdding: .day, value: 1, to: targetTime) ?? targetTime
        }

        let components = calendar.dateComponents([.hour, .minute], from: now, to: effectiveDate)
        if let hours = components.hour, let minutes = components.minute {
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
        return "Soon"
    }
}

struct SmartAlarmRow: View {
    let alarm: SmartWakeAlarm
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.formattedTime)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(alarm.isEnabled ? Theme.textPrimary : Theme.textSecondary.opacity(0.5))

                Text("\(alarm.label) · \(alarm.windowMinutes)m window")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: alarm.isEnabled ? "bell.fill" : "bell.slash")
                    .font(.title3)
                    .foregroundColor(alarm.isEnabled ? Theme.warningAccent : Theme.textSecondary)
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundColor(Theme.heartRate)
            }
        }
        .padding()
        .glassCard()
    }
}

struct HowItWorksStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Theme.deepSleep)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(1)
            }
        }
    }
}

// MARK: - Smart Wake Settings Sheet

struct SmartWakeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let alarm: SmartWakeAlarm?
    let onSave: (SmartWakeAlarm) -> Void

    @State private var targetTime: Date = Date()
    @State private var windowMinutes: Double = 30
    @State private var label: String = "Wake up"
    @State private var vibrate: Bool = true
    @State private var selectedDays: Set<SmartWakeAlarm.Weekday> = Set(SmartWakeAlarm.Weekday.allCases)

    private let windowOptions: [Double] = [15, 20, 30, 45, 60]

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
                        // Time Picker
                        VStack(spacing: 12) {
                            Text("Wake Time")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)

                            DatePicker("", selection: $targetTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorMultiply(Theme.deepSleep)
                        }
                        .padding()
                        .glassCard()

                        // Window Picker
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Wake Window")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                Spacer()

                                Text("\(Int(windowMinutes)) minutes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.deepSleep)
                            }

                            HStack(spacing: 8) {
                                ForEach(windowOptions, id: \.self) { mins in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            windowMinutes = mins
                                        }
                                    } label: {
                                        Text("\(Int(mins))m")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(windowMinutes == mins ? .white : Theme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(windowMinutes == mins ? Theme.deepSleep : Theme.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }

                            Text("We'll wake you during light sleep within this window, starting at your target time.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary.opacity(0.7))
                                .lineSpacing(2)
                        }
                        .padding()
                        .glassCard()

                        // Label
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Label")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)

                            TextField("Alarm label", text: $label)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding()
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .glassCard()

                        // Vibrate Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $vibrate) {
                                HStack(spacing: 12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundColor(Theme.deepSleep)
                                    Text("Vibrate on wake")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .tint(Theme.deepSleep)
                        }
                        .padding()
                        .glassCard()

                        // Days
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Repeat")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)

                            HStack(spacing: 8) {
                                ForEach(SmartWakeAlarm.Weekday.allCases, id: \.self) { day in
                                    let isSelected = selectedDays.contains(day)
                                    Button {
                                        if isSelected {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    } label: {
                                        Text(day.shortName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(isSelected ? .white : Theme.textSecondary)
                                            .frame(width: 36, height: 36)
                                            .background(isSelected ? Theme.deepSleep : Theme.surface)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .glassCard()

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(alarm == nil ? "New Smart Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .font(.headline)
                    .foregroundColor(Theme.deepSleep)
                }
            }
        }
        .onAppear {
            if let alarm = alarm {
                targetTime = alarm.targetTime
                windowMinutes = Double(alarm.windowMinutes)
                label = alarm.label
                vibrate = alarm.vibrate
                selectedDays = Set(alarm.days)
            }
        }
    }

    private func saveAlarm() {
        let newAlarm = SmartWakeAlarm(
            id: alarm?.id ?? UUID(),
            targetTime: targetTime,
            windowMinutes: Int(windowMinutes),
            isEnabled: alarm?.isEnabled ?? true,
            label: label,
            soundName: alarm?.soundName ?? "gentle_rise",
            vibrate: vibrate,
            days: Array(selectedDays).sorted { $0.rawValue < $1.rawValue }
        )
        onSave(newAlarm)
        dismiss()
    }
}
