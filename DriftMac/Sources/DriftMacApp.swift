import SwiftUI

@main
struct DriftMacApp: App {
    @State private var showPopover = false
    @State private var menuBarTimer: Date?
    @State private var currentPhase: SleepPhase = .awake
    @State private var sleepScore: Int = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 320, height: 400)

        MenuBarExtra {
            MenuBarView(
                showPopover: $showPopover,
                currentPhase: $currentPhase,
                sleepScore: $sleepScore
            )
        } label: {
            Image(systemName: "moon.fill")
                .foregroundStyle(.purple)
        }
        .menuBarExtraStyle(.window)
    }
}
