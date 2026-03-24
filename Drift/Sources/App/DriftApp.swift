import SwiftUI

@main
struct DriftApp: App {
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var databaseService = DatabaseService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
                .environmentObject(databaseService)
                .preferredColorScheme(.dark)
        }
    }
}
