import Foundation

/// App Store content for Drift — used in Info.plist or a dedicated store listing doc
enum AppStoreContent {

    // MARK: - App Description (long)
    static let description = """
    Drift transforms your Apple Watch sleep data into a morning briefing you'll actually read.

    Every night, your Apple Watch tracks your sleep stages — deep, REM, light, and awake. Drift reads that data and turns it into a single sleep score (0-100) plus a plain-English insight: "You slept 40 minutes less than usual but your deep sleep was 20% higher. Probably because you skipped the second glass of wine."

    A week in, Drift starts showing patterns. A month in, it shows trends, correlations, and gentle suggestions.

    WHAT DRIFT TRACKS
    — Sleep stages: deep, REM, light, and awake — with colored breakdowns
    — Sleep score: a single number that captures how well you slept
    — Overnight heart rate: min, max, and average
    — Sleep timing: when you fell asleep and when you woke up

    SLEEP INSIGHTS (Premium)
    — Weekly AI insights: pattern detection and personalized tips
    — 30-day history with trend charts
    — Correlation analysis: "Deep sleep improves on nights without caffeine after 4pm"
    — Family sharing: up to 5 members

    HOW IT WORKS
    1. Wear your Apple Watch to bed
    2. Open Drift in the morning
    3. Read your score, your stages, and what it means

    PRIVACY
    Your sleep data stays on your device. Drift reads from Apple Health — it doesn't store your data on any server.

    Requires Apple Watch with sleep tracking enabled.
    """

    // MARK: - Short Description
    static let shortDescription = "Understand your sleep with AI-powered insights from your Apple Watch."

    // MARK: - Keywords
    static let keywords = [
        "sleep tracker",
        "sleep stages",
        "apple watch sleep",
        "sleep score",
        "sleep analysis",
        "sleep insights",
        "REM sleep",
        "deep sleep",
        "healthkit",
        "sleep monitor",
        "sleep quality",
        "night tracker",
        "rest",
        "insomnia",
        "sleep patterns"
    ]

    // MARK: - Marketing Keywords (comma-separated string for App Store Connect)
    static let keywordsString = keywords.joined(separator: ", ")

    // MARK: - App Icon Concept
    /*
     App Icon Concept:
     - Deep navy/indigo background (#08090f to #0d1020 gradient)
     - A crescent moon, partially overlapping, rendered in soft white/silver
     - Three small stars arranged in a diagonal above/right of the moon
     - The icon is circular (standard iOS app icon shape)
     - Typography: none — purely graphical
     - Mood: calm, nocturnal, premium
     - Visual style: flat with subtle gradients, no outlines
     */
}
