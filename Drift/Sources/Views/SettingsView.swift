import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var smartWakeService: SmartWakeService
    @Binding var showPricing: Bool
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showOuraSheet = false
    @State private var showWithingsSheet = false
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.background, Theme.backgroundGradient],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                List {
                    Section {
                        healthKitStatusRow
                    } header: {
                        Text("HealthKit")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        ouraRow
                        withingsRow
                    } header: {
                        Text("Device Integrations")
                            .foregroundColor(Theme.textSecondary)
                    } footer: {
                        if subscriptionManager.currentTier == .free {
                            Text("Upgrade to Insights to connect Oura Ring and Withings scale.")
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        NavigationLink {
                            SmartWakeView()
                        } label: {
                            HStack {
                                SettingsRow(
                                    icon: "alarm.watch",
                                    iconColor: Theme.deepSleep,
                                    title: "Smart Wake"
                                )
                                Spacer()
                                if let nextAlarm = smartWakeService.nextAlarm(), nextAlarm.isEnabled {
                                    Text(nextAlarm.formattedTime)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.insightAccent)
                                }
                            }
                        }

                        NavigationLink {
                            WeeklyReportView()
                        } label: {
                            SettingsRow(
                                icon: "doc.text.fill",
                                iconColor: Theme.remSleep,
                                title: "Weekly Reports"
                            )
                        }
                    } header: {
                        Text("Sleep Features")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        exportRow
                    } header: {
                        Text("Data")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        Button {
                            showPricing = true
                        } label: {
                            HStack {
                                SettingsRow(
                                    icon: "crown.fill",
                                    iconColor: Theme.warningAccent,
                                    title: "Upgrade to Premium"
                                )
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        Toggle(isOn: $notificationsEnabled) {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: Theme.warningAccent,
                                title: "Morning Notifications"
                            )
                        }
                        .tint(Theme.deepSleep)

                        Toggle(isOn: $hapticFeedback) {
                            SettingsRow(
                                icon: "hand.tap.fill",
                                iconColor: Theme.insightAccent,
                                title: "Haptic Feedback"
                            )
                        }
                        .tint(Theme.deepSleep)
                    } header: {
                        Text("Subscription & Preferences")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        NavigationLink {
                            AboutView()
                        } label: {
                            SettingsRow(
                                icon: "info.circle.fill",
                                iconColor: Theme.lightSleep,
                                title: "About Drift"
                            )
                        }

                        Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                            SettingsRow(
                                icon: "lock.shield.fill",
                                iconColor: Theme.deepSleep,
                                title: "Privacy Policy"
                            )
                        }
                    } header: {
                        Text("Information")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surfaceGlass)

                    Section {
                        HStack {
                            Spacer()
                            Text("Drift v1.0.0")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showOuraSheet) {
                OuraIntegrationView()
            }
            .sheet(isPresented: $showWithingsSheet) {
                WithingsIntegrationView()
            }
            .sheet(isPresented: $showExportSheet) {
                HealthExportView()
            }
        }
    }

    private var healthKitStatusRow: some View {
        HStack {
            Image(systemName: healthKitService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(healthKitService.isAuthorized ? Theme.insightAccent : Theme.heartRate)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit Access")
                    .foregroundColor(Theme.textPrimary)
                Text(healthKitService.isAuthorized ? "Authorized" : "Not Authorized")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            if !healthKitService.isAuthorized {
                Button("Enable") {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
                .font(.subheadline.bold())
                .foregroundColor(Theme.deepSleep)
            }
        }
    }

    @StateObject private var ouraService = OuraService()

    private var ouraRow: some View {
        Button {
            if subscriptionManager.canAccess(.ouraIntegration) {
                showOuraSheet = true
            } else {
                showPricing = true
            }
        } label: {
            HStack {
                Image(systemName: ouraService.isConnected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(ouraService.isConnected ? Theme.insightAccent : Theme.textSecondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Oura Ring")
                        .foregroundColor(Theme.textPrimary)
                    Text(ouraService.isConnected ? "Connected" : "Connect your Oura Ring")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if !subscriptionManager.canAccess(.ouraIntegration) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    @StateObject private var withingsService = WithingsService()

    private var withingsRow: some View {
        Button {
            if subscriptionManager.canAccess(.withingsIntegration) {
                showWithingsSheet = true
            } else {
                showPricing = true
            }
        } label: {
            HStack {
                Image(systemName: withingsService.isConnected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(withingsService.isConnected ? Theme.insightAccent : Theme.textSecondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Withings Scale")
                        .foregroundColor(Theme.textPrimary)
                    Text(withingsService.isConnected ? "Connected" : "Connect your Withings account")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if !subscriptionManager.canAccess(.withingsIntegration) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private var exportRow: some View {
        Button {
            if subscriptionManager.canAccess(.healthExport) {
                showExportSheet = true
            } else {
                showPricing = true
            }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Theme.lightSleep)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Export Health Data")
                        .foregroundColor(Theme.textPrimary)
                    Text("Download your sleep data")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if !subscriptionManager.canAccess(.healthExport) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundGradient],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deepSleep, Theme.remSleep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Drift")
                        .font(.largeTitle.bold())
                        .foregroundColor(Theme.textPrimary)

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                Text("Understand your sleep.")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)
                    .italic()

                Spacer()

                VStack(spacing: 8) {
                    Text("Sleep data powered by Apple HealthKit")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("Your data never leaves your device.")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Oura Integration View

struct OuraIntegrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ouraService = OuraService()
    @State private var accessToken = ""
    @State private var isConnecting = false
    @State private var connectionError: String?

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
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "circle.hexagongrid.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.deepSleep, Theme.remSleep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Connect Oura Ring")
                                .font(.title2.bold())
                                .foregroundColor(Theme.textPrimary)

                            Text("Import your Oura sleep data to get deeper insights and combine with Apple Watch data.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 32)

                        // Status
                        if ouraService.isConnected {
                            connectedCard
                        } else {
                            connectCard
                        }

                        // Instructions
                        instructionsCard

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Oura Ring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.deepSleep)
                }
            }
        }
        .onAppear {
            if let token = ouraService.accessToken {
                Task {
                    await ouraService.connect(with: token)
                }
            }
        }
    }

    private var connectedCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.insightAccent)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    if let lastSync = ouraService.lastSyncDate {
                        Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()
            }
            .padding()
            .glassCard()

            Button {
                ouraService.disconnect()
            } label: {
                Text("Disconnect")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.heartRate)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.heartRate.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var connectCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal Access Token")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                TextField("Paste your Oura token", text: $accessToken)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .padding()
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if let error = connectionError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Theme.heartRate)
            }

            Button {
                isConnecting = true
                connectionError = nil
                Task {
                    let success = await ouraService.connect(with: accessToken)
                    isConnecting = false
                    if !success {
                        connectionError = "Invalid token. Please check and try again."
                    }
                }
            } label: {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isConnecting ? "Connecting..." : "Connect Oura")
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
            .disabled(accessToken.isEmpty || isConnecting)
        }
        .padding()
        .glassCard()
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to get your token")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(alignment: .leading, spacing: 8) {
                InstructionStep(number: 1, text: "Visit cloud.ouraring.com/personal-access-token")
                InstructionStep(number: 2, text: "Sign in with your Oura account")
                InstructionStep(number: 3, text: "Create a new Personal Access Token")
                InstructionStep(number: 4, text: "Copy and paste the token above")
            }
        }
        .padding()
        .glassCard()
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Theme.deepSleep)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Withings Integration View

struct WithingsIntegrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var withingsService = WithingsService()
    @State private var isConnecting = false
    @State private var connectionError: String?

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
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.deepSleep, Theme.remSleep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Connect Withings")
                                .font(.title2.bold())
                                .foregroundColor(Theme.textPrimary)

                            Text("Sync your weight, body composition, and activity data from your Withings scale.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 32)

                        // Status
                        if withingsService.isConnected {
                            connectedCard
                        } else {
                            connectCard
                        }

                        // Info
                        infoCard

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Withings Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.deepSleep)
                }
            }
        }
    }

    private var connectedCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.insightAccent)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    if let lastSync = withingsService.lastSyncDate {
                        Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()
            }
            .padding()
            .glassCard()

            Button {
                withingsService.disconnect()
            } label: {
                Text("Disconnect")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.heartRate)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.heartRate.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var connectCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Withings uses OAuth 2.0 for secure authentication.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                // In a real implementation, open the OAuth URL
                // For now, show setup instructions
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open Withings Authorization")
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

            if let error = connectionError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Theme.heartRate)
            }
        }
        .padding()
        .glassCard()
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What syncs from Withings")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(alignment: .leading, spacing: 8) {
                SyncItem(icon: "scalemass.fill", text: "Weight & body composition")
                SyncItem(icon: "heart.fill", text: "Blood pressure")
                SyncItem(icon: "waveform.path.ecg", text: "Heart rate")
                SyncItem(icon: "figure.walk", text: "Daily steps & activity")
            }
        }
        .padding()
        .glassCard()
    }
}

struct SyncItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.insightAccent)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Health Export View

struct HealthExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthExportService = HealthExportService()
    @StateObject private var sleepExportService = SleepExportService()
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedFormat: ExportFormatOption = .pdf
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var exportedCount = 0
    @State private var showShareSheet = false
    @State private var exportError: String?

    enum ExportFormatOption {
        case pdf, json, csv
    }

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
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.deepSleep, Theme.remSleep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Export Your Data")
                                .font(.title2.bold())
                                .foregroundColor(Theme.textPrimary)

                            Text("Download your sleep history for backup, medical consultations, or personal analysis.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 32)

                        // Format picker
                        formatPickerCard

                        // Export status
                        if let error = exportError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.heartRate)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(Theme.heartRate)
                                Spacer()
                            }
                            .padding()
                            .glassCard()
                        }

                        // HealthKit sync card
                        exportToHealthKitCard

                        // Last export info
                        if let lastExport = healthExportService.lastExportDate {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.insightAccent)
                                Text("Last synced to HealthKit: \(lastExport.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                            }
                            .padding()
                            .glassCard()
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.deepSleep)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var formatPickerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Format")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 12) {
                FormatOption(
                    title: "PDF",
                    subtitle: "Report",
                    icon: "doc.richtext.fill",
                    isSelected: selectedFormat == .pdf
                ) {
                    selectedFormat = .pdf
                }

                FormatOption(
                    title: "JSON",
                    subtitle: "Full data",
                    icon: "curlybraces",
                    isSelected: selectedFormat == .json
                ) {
                    selectedFormat = .json
                }

                FormatOption(
                    title: "CSV",
                    subtitle: "Spreadsheet",
                    icon: "tablecells",
                    isSelected: selectedFormat == .csv
                ) {
                    selectedFormat = .csv
                }
            }

            Text(formatDescription)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
                .lineSpacing(2)

            Button {
                isExporting = true
                exportError = nil
                Task {
                    do {
                        let records = healthKitService.weeklySleep
                        switch selectedFormat {
                        case .pdf:
                            exportURL = try await sleepExportService.generatePDFReport(records: records)
                        case .json:
                            exportURL = try await sleepExportService.generateJSONExport(records: records)
                        case .csv:
                            exportURL = try await sleepExportService.generateCSVExport(records: records)
                        }
                        isExporting = false
                        showShareSheet = true
                    } catch {
                        isExporting = false
                        exportError = "Export failed: \(error.localizedDescription)"
                    }
                }
            } label: {
                HStack {
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isExporting ? "Exporting..." : "Export \(formatName)")
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
            .disabled(isExporting)
        }
        .padding()
        .glassCard()
    }

    private var formatDescription: String {
        switch selectedFormat {
        case .pdf:
            return "A formatted PDF report with your sleep scores, trends, and insights — ideal for sharing with your doctor."
        case .json:
            return "Complete machine-readable data export including all sleep stages, vitals, and metadata."
        case .csv:
            return "Spreadsheet-compatible format with one row per night. Opens in Excel, Google Sheets, etc."
        }
    }

    private var formatName: String {
        switch selectedFormat {
        case .pdf: return "PDF Report"
        case .json: return "JSON"
        case .csv: return "CSV"
        }
    }

    private var exportToHealthKitCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apple Health Sync")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Text("Write your Drift sleep data back to Apple Health so other apps can read it.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 12) {
                Button {
                    Task {
                        exportedCount = await healthExportService.exportAllFromDatabase()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                        Text("Sync to HealthKit")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.deepSleep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.deepSleep.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task {
                        exportedCount = await healthExportService.exportAllFromDatabase()
                    }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if exportedCount > 0 {
                Text("Successfully synced \(exportedCount) sleep records to HealthKit.")
                    .font(.caption)
                    .foregroundColor(Theme.insightAccent)
            }
        }
        .padding()
        .glassCard()
    }
}

struct FormatOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.deepSleep : Theme.textSecondary)

                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Theme.deepSleep.opacity(0.15) : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.deepSleep : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
