import SwiftUI

// MARK: - Theme - Design Tokens for Drift iOS 26 Liquid Glass

enum Theme {
    // MARK: - Colors

    /// Primary background - pure dark for maximum contrast
    static let background = Color(hex: "0A0E1A")

    /// Background gradient endpoint
    static let backgroundGradient = Color(hex: "0F1629")

    /// Elevated surface with glass effect
    static let surface = Color(hex: "161B2E")

    /// Glass card background with transparency
    static let glassBackground = Color(hex: "1A2035").opacity(0.7)

    /// Surface glass for list rows
    static let surfaceGlass = Color(hex: "161B2E").opacity(0.6)

    /// Tertiary text - for less important text
    static let textTertiary = Color(hex: "6B7280")

    /// Quaternary text - for hints, placeholders
    static let textQuaternary = Color(hex: "4B5563")

    /// Primary text
    static let textPrimary = Color(hex: "F9FAFB")

    /// Secondary text
    static let textSecondary = Color(hex: "9CA3AF")

    /// Separator/divider color
    static let separator = Color(hex: "1F2937")

    /// Primary accent - deep sleep blue
    static let deepSleep = Color(hex: "4F46E5")

    /// REM sleep purple
    static let remSleep = Color(hex: "7C3AED")

    /// Light sleep teal
    static let lightSleep = Color(hex: "14B8A6")

    /// Awake/alert state
    static let awake = Color(hex: "F59E0B")

    /// Heart rate red
    static let heartRate = Color(hex: "EF4444")

    /// Insight accent - green for positive
    static let insightAccent = Color(hex: "10B981")

    /// Warning accent - amber
    static let warningAccent = Color(hex: "F59E0B")

    // MARK: - Corner Radius Tokens

    /// Small corner radius (8pt) - for small components
    static let cornerRadiusSmall: CGFloat = 8

    /// Medium corner radius (12pt) - for cards, buttons
    static let cornerRadiusMedium: CGFloat = 12

    /// Large corner radius (16pt) - for major containers
    static let cornerRadiusLarge: CGFloat = 16

    /// Extra large corner radius (20pt) - for modals, sheets
    static let cornerRadiusXLarge: CGFloat = 20

    /// Pill shape corner radius (full height / 2)
    static let cornerRadiusPill: CGFloat = 9999

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
    static let spacingXXXL: CGFloat = 32

    // MARK: - Background Depth Levels

    /// Level 0 - Base background
    static let backgroundLevel0 = background

    /// Level 1 - Slight elevation
    static let backgroundLevel1 = Color(hex: "0D111F")

    /// Level 2 - Cards, surfaces
    static let backgroundLevel2 = Color(hex: "111827")

    /// Level 3 - Modals, overlays
    static let backgroundLevel3 = Color(hex: "161B2E")

    // MARK: - Haptic Feedback

    /// Trigger a light haptic tap
    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger a selection haptic
    static func selectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Trigger a success notification haptic
    static func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Trigger a warning notification haptic
    static func warningHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Trigger an error notification haptic
    static func errorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Button Styles

    /// Primary action button style
    struct PrimaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
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
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }

    /// Secondary/ghost button style
    struct SecondaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline.bold())
                .foregroundColor(Theme.deepSleep)
                .padding(.horizontal, Theme.spacingL)
                .padding(.vertical, Theme.spacingM)
                .background(Theme.deepSleep.opacity(configuration.isPressed ? 0.2 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }

    /// Destructive button style
    struct DestructiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline.bold())
                .foregroundColor(Theme.heartRate)
                .padding(.horizontal, Theme.spacingL)
                .padding(.vertical, Theme.spacingM)
                .background(Theme.heartRate.opacity(configuration.isPressed ? 0.2 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }

    // MARK: - Glass Card Modifier

    struct GlassCardModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(Theme.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                        .fill(Theme.glassBackground)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass card styling
    func glassCard() -> some View {
        modifier(Theme.GlassCardModifier())
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme-Consistent Score Color

extension Theme {
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 85...100: return insightAccent
        case 70..<85: return deepSleep
        case 55..<70: return warningAccent
        case 40..<55: return awake
        default: return heartRate
        }
    }
}
