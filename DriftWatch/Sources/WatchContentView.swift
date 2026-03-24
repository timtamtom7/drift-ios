import SwiftUI
import HealthKit

struct WatchContentView: View {
    @State private var sleepData: WatchSleepData?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let data = sleepData {
                    sleepView(data: data)
                } else {
                    noDataView
                }
            }
            .navigationTitle("Drift")
            .task {
                await fetchSleepData()
            }
        }
    }

    private func sleepView(data: WatchSleepData) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Sleep Score Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(data.score) / 100)
                        .stroke(scoreColor(data.score), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(data.score)")
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundColor(.white)
                        Text("score")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 8)

                // Total Sleep
                VStack(spacing: 4) {
                    Text(data.totalDuration)
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(.white)
                    Text("Total Sleep")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                // Sleep Stages
                HStack(spacing: 6) {
                    WatchSleepStageBar(stage: .deep, minutes: data.deepMinutes, total: data.totalMinutes)
                    WatchSleepStageBar(stage: .rem, minutes: data.remMinutes, total: data.totalMinutes)
                    WatchSleepStageBar(stage: .light, minutes: data.lightMinutes, total: data.totalMinutes)
                    WatchSleepStageBar(stage: .awake, minutes: data.awakeMinutes, total: data.totalMinutes)
                }
                .frame(height: 40)

                // Time Range
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.fellAsleepFormatted)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("Bedtime")
                            .font(.caption2)
                            .opacity(0.6)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(data.wokeUpFormatted)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("Wake up")
                            .font(.caption2)
                            .opacity(0.6)
                    }
                }

                // HRV if available
                if let hrv = data.hrv {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        Text("HRV: \(hrv)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.system(size: 36))
                .foregroundColor(.gray)

            Text("No sleep data")
                .font(.headline)
                .foregroundColor(.white)

            Text("Wear your Apple Watch to bed and sync in the morning.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 65..<80: return .blue
        case 50..<65: return .orange
        default: return .red
        }
    }

    private func fetchSleepData() async {
        isLoading = true
        defer { isLoading = false }

        guard HKHealthStore.isHealthDataAvailable() else { return }

        let healthStore = HKHealthStore()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [sleepType])

            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = now

            let predicate = HKQuery.predicateForSamples(withStart: startOfToday, adding: nil, end: endOfToday, options: .strictStartDate)

            let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
                healthStore.execute(query)
            }

            if samples.isEmpty {
                sleepData = nil
                return
            }

            var deepMinutes = 0
            var remMinutes = 0
            var lightMinutes = 0
            var awakeMinutes = 0

            for sample in samples {
                let minutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepMinutes += minutes
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remMinutes += minutes
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    lightMinutes += minutes
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awakeMinutes += minutes
                default:
                    lightMinutes += minutes
                }
            }

            let totalMinutes = deepMinutes + remMinutes + lightMinutes + awakeMinutes
            let fellAsleep = samples.first?.startDate ?? startOfToday
            let wokeUp = samples.last?.endDate ?? endOfToday

            // Calculate score
            let score = calculateScore(deep: deepMinutes, rem: remMinutes, awake: awakeMinutes, total: totalMinutes)

            sleepData = WatchSleepData(
                score: score,
                totalDuration: formatDuration(totalMinutes),
                deepMinutes: deepMinutes,
                remMinutes: remMinutes,
                lightMinutes: lightMinutes,
                awakeMinutes: awakeMinutes,
                totalMinutes: totalMinutes,
                fellAsleep: fellAsleep,
                wokeUp: wokeUp,
                hrv: nil
            )
        } catch {
            print("Failed to fetch sleep data: \(error)")
            sleepData = nil
        }
    }

    private func calculateScore(deep: Int, rem: Int, awake: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }

        let deepRatio = Double(deep) / Double(total)
        let remRatio = Double(rem) / Double(total)
        let awakeRatio = Double(awake) / Double(total)

        let durationScore: Double
        if total >= 420 && total <= 540 {
            durationScore = 100
        } else if total < 420 {
            durationScore = max(0, Double(total) / 420.0 * 100)
        } else {
            durationScore = max(0, 100 - Double(total - 540) / 60.0 * 20)
        }

        let deepScore = min(100, deepRatio * 400)
        let remScore = min(100, remRatio * 300)
        let awakePenalty = awakeRatio * 150

        let score = Int(durationScore * 0.3 + deepScore * 0.3 + remScore * 0.25 + (100 - awakePenalty) * 0.15)
        return min(100, max(0, score))
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Sleep Data Model

struct WatchSleepData {
    let score: Int
    let totalDuration: String
    let deepMinutes: Int
    let remMinutes: Int
    let lightMinutes: Int
    let awakeMinutes: Int
    let totalMinutes: Int
    let fellAsleep: Date
    let wokeUp: Date
    let hrv: Int?

    var fellAsleepFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: fellAsleep)
    }

    var wokeUpFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: wokeUp)
    }
}

// MARK: - Sleep Stage Bar

enum WatchSleepStage {
    case deep, rem, light, awake

    var color: Color {
        switch self {
        case .deep: return Color(hex: "4A90D9")
        case .rem: return Color(hex: "9B59B6")
        case .light: return Color(hex: "5DADE2")
        case .awake: return Color(hex: "E74C3C")
        }
    }

    var label: String {
        switch self {
        case .deep: return "Deep"
        case .rem: return "REM"
        case .light: return "Light"
        case .awake: return "Awake"
        }
    }
}

struct WatchSleepStageBar: View {
    let stage: WatchSleepStage
    let minutes: Int
    let total: Int

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let height = total > 0 ? CGFloat(minutes) / CGFloat(max(total, 1)) * geo.size.height : 0
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stage.color)
                        .frame(height: max(4, height))
                }
            }

            Text("\(minutes)m")
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - HealthKit Extension

extension HKQuery {
    static func predicateForSamples(
        withStart startDate: Date,
        adding interval: DateComponents?,
        end endDate: Date,
        options: HKQueryOptions
    ) -> NSPredicate {
        return HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: options)
    }
}
