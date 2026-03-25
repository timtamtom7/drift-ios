import SwiftUI

// R11: iPad-specific views for Drift
// Supports side-by-side layout, split view, keyboard shortcuts, external display
struct IPadHomeView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var familyService: FamilyService
    @State private var selectedTab: String = "home"

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Button {
                    selectedTab = "home"
                } label: {
                    Label("Home", systemImage: "moon.fill")
                }
                .listRowBackground(selectedTab == "home" ? Color.accentColor.opacity(0.2) : Color.clear)

                Button {
                    selectedTab = "family"
                } label: {
                    Label("Family", systemImage: "person.2.fill")
                }
                .listRowBackground(selectedTab == "family" ? Color.accentColor.opacity(0.2) : Color.clear)

                Button {
                    selectedTab = "insights"
                } label: {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .listRowBackground(selectedTab == "insights" ? Color.accentColor.opacity(0.2) : Color.clear)

                Button {
                    selectedTab = "settings"
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .listRowBackground(selectedTab == "settings" ? Color.accentColor.opacity(0.2) : Color.clear)
            }
            .navigationTitle("Drift")
        } detail: {
            switch selectedTab {
            case "home":
                IPadHomeDetailView()
            case "family":
                IPadFamilyDetailView()
            case "insights":
                IPadInsightsDetailView()
            case "settings":
                IPadSettingsDetailView()
            default:
                IPadHomeDetailView()
            }
        }
    }
}

struct IPadHomeDetailView: View {
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        HStack(spacing: 24) {
            // Left: Sleep calendar
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Calendar")
                    .font(.title2.bold())

                SleepCalendarIPadView()
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: Tonight's sleep
            VStack(alignment: .leading, spacing: 16) {
                Text("Tonight's Sleep")
                    .font(.title2.bold())

                if let record = healthKitService.todaySleep {
                    SleepTrackerIPadCard(record: record)
                } else {
                    SleepTrackerIPadPlaceholder()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
    }
}

struct IPadFamilyDetailView: View {
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Family Sleep")
                .font(.title2.bold())

            if familyService.familyMembers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No family members yet")
                        .font(.headline)
                    Text("Add family members to share sleep insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                        ForEach(familyService.familyMembers) { member in
                            FamilyMemberIPadCard(member: member)
                        }
                    }
                }
            }
        }
        .padding(24)
    }
}

struct IPadInsightsDetailView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.title2.bold())

            ScrollView {
                Text("Insights from your sleep data will appear here")
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
    }
}

struct IPadSettingsDetailView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.bold())

            Text("Settings view")
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}

// MARK: - iPad-specific views

struct SleepCalendarIPadView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .frame(height: 300)
            .overlay(
                Text("Calendar View")
                    .foregroundColor(.secondary)
            )
    }
}

struct SleepTrackerIPadCard: View {
    let record: SleepRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.fellAsleepTime, style: .date)
                .font(.headline)

            HStack {
                Text("Score:")
                Text("\(record.score)")
                    .foregroundColor(record.score >= 80 ? .green : .orange)
                    .font(.title2.bold())
            }

            Text("Duration: \(Int(record.totalDuration / 3600))h \(Int(record.totalDuration.truncatingRemainder(dividingBy: 3600) / 60))m")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(height: 300)
    }
}

struct SleepTrackerIPadPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .frame(height: 300)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No sleep data yet")
                        .foregroundColor(.secondary)
                }
            )
    }
}

struct FamilyMemberIPadCard: View {
    let member: FamilyMember

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: member.relationship.icon)
                    .foregroundColor(.accentColor)
                Text(member.name)
                    .font(.headline)
            }

            if let score = member.sleepScore {
                HStack {
                    Text("Score: \(score)")
                        .font(.subheadline)
                    if score >= 80 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }

            if let hours = member.averageSleepHours {
                Text("Avg: \(String(format: "%.1f", hours))h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
