import AppIntents

/// "Play Morning Briefing": the action for Shortcuts and Siri, for example
/// in an automation "When my alarm is stopped". It plays even when the phone is locked.
struct PlayBriefingIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play Morning Briefing"
    static let description = IntentDescription("Plays today's morning briefing.")

    @MainActor
    func perform() async throws -> some IntentResult {
        try await BriefingPlayer.shared.playLatest()
        return .result()
    }
}

/// Runs when the in-app alarm is stopped: the alarm goes quiet and the briefing starts.
struct PlayBriefingFromAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Play Morning Briefing after the alarm"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        try await BriefingPlayer.shared.playLatest()
        return .result()
    }
}

/// Makes the action appear in Shortcuts and Siri without any setup.
struct BriefingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayBriefingIntent(),
            phrases: ["Play my \(.applicationName)", "Start my \(.applicationName)"],
            shortTitle: "Play Briefing",
            systemImageName: "sunrise.fill"
        )
    }
}
