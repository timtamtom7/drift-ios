import Cocoa
import SwiftUI

@main
struct DriftMacApp: App {
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var databaseService = DatabaseService()
    @StateObject private var smartWakeService = SmartWakeService()

    var body: some Scene {
        WindowGroup {
            MacHomeView()
                .environmentObject(healthKitService)
                .environmentObject(databaseService)
                .environmentObject(smartWakeService)
                .frame(minWidth: 900, minHeight: 700)
                .darkMode()
        }
    }
}

extension View {
    func darkMode() -> some View {
        self.preferredColorScheme(.dark)
    }
}
