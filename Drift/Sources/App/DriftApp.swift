import SwiftUI

@main
struct DriftApp: App {
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var databaseService = DatabaseService()
    @StateObject private var smartWakeService = SmartWakeService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
                .environmentObject(databaseService)
                .environmentObject(smartWakeService)
                .preferredColorScheme(.dark)
        }
    }
}
