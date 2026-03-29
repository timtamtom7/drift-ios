import Foundation
import AppKit
import AVFoundation

/// Smart Wake Service - wakes user during light sleep phase within a configurable window
final class SmartWakeService: ObservableObject, @unchecked Sendable {
    static let shared = SmartWakeService()

    @Published private(set) var isArmed = false
    @Published private(set) var currentPhase: SleepPhase = .awake
    @Published private(set) var wakeTime: Date?

    private var wakeWindowMinutes: Int = 30
    private var targetWakeTime: Date?
    private var monitoringTimer: Timer?
    private var audioPlayer: AVAudioPlayer?

    private let healthKitService = HealthKitService.shared

    private init() {}

    // MARK: - Configuration

    func configure(windowMinutes: Int = 30) {
        wakeWindowMinutes = max(5, min(60, windowMinutes))
    }

    // MARK: - Arm/Disarm

    func arm(for wakeTime: Date) {
        self.targetWakeTime = wakeTime
        self.wakeTime = wakeTime
        isArmed = true
        startMonitoring()
    }

    func disarm() {
        isArmed = false
        targetWakeTime = nil
        stopMonitoring()
        currentPhase = .awake
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        stopMonitoring()

        // Check every 5 minutes for sleep phase
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkAndWake()
            }
        }

        // Also trigger immediately
        Task {
            await checkAndWake()
        }
    }

    private func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func checkAndWake() async {
        guard isArmed, let target = targetWakeTime else { return }

        let now = Date()
        let windowStart = target.addingTimeInterval(-Double(wakeWindowMinutes * 60))
        let windowEnd = target

        // Only attempt wake within the window
        guard now >= windowStart && now <= windowEnd else {
            // Outside window - check if we should auto-wake at exact time
            if now >= windowEnd {
                await triggerWake()
            }
            return
        }

        // Detect current sleep phase using movement data
        let phase = await detectSleepPhase()

        // Wake if in light sleep or REM (safe wake phases)
        switch phase {
        case .light, .rem, .awake:
            await triggerWake()
        case .deep:
            // Don't wake during deep sleep - wait for lighter phase
            currentPhase = .deep
            break
        }
    }

    private func detectSleepPhase() async -> SleepPhase {
        // Get recent movement data (last 15 minutes)
        let now = Date()
        let fifteenMinutesAgo = now.addingTimeInterval(-900)

        do {
            let movementData = try await healthKitService.getMovementData(from: fifteenMinutesAgo, to: now)
            return analyzeMovementForPhase(movementData)
        } catch {
            // Fallback: assume light sleep if we can't determine
            return .light
        }
    }

    private func analyzeMovementForPhase(_ movement: [Double]) -> SleepPhase {
        guard !movement.isEmpty else { return .light }

        let averageMovement = movement.reduce(0, +) / Double(movement.count)
        let maxMovement = movement.max() ?? 0

        // Classification based on movement patterns
        if averageMovement < 5 && maxMovement < 20 {
            // Very low movement = deep sleep
            return .deep
        } else if averageMovement < 20 && maxMovement < 50 {
            // Moderate movement = light sleep
            return .light
        } else if averageMovement >= 20 && maxMovement >= 50 {
            // Higher movement with variability = REM (dreaming)
            return .rem
        } else {
            return .light
        }
    }

    // MARK: - Wake Trigger

    private func triggerWake() async {
        guard isArmed else { return }

        // Play gentle alarm sound
        playGentleAlarm()

        // Show notification
        showWakeNotification()

        // Update state
        isArmed = false
        targetWakeTime = nil

        // Stop monitoring
        stopMonitoring()
    }

    private func playGentleAlarm() {
        // Use system sound or custom gentle tone
        // NSSound(named:) for built-in sounds
        if let sound = NSSound(named: .init("Fountain")) {
            sound.volume = 0.5
            sound.play()
        } else {
            // Fallback: use AudioServicesPlaySystemSound for a gentle notification
            AudioServicesPlaySystemSound(1007) // Soft chime
        }
    }

    private func showWakeNotification() {
        let notification = NSUserNotification()
        notification.title = "☀️ Good Morning!"
        notification.subtitle = "Time to start your day feeling refreshed."
        notification.soundName = nil // We handle sound ourselves

        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Sleep Phase Extension

extension SmartWakeService {
    /// Returns a human-readable description of the current phase
    var phaseDescription: String {
        switch currentPhase {
        case .awake:
            return "You're awake"
        case .light:
            return "Light sleep detected"
        case .deep:
            return "Deep sleep - waiting for lighter phase"
        case .rem:
            return "REM sleep - good time to wake"
        }
    }
}
