import ActivityKit
import AlarmKit
import Foundation
import Observation
import SwiftUI

struct BriefingAlarmMetadata: AlarmMetadata {}

/// The wake-up alarm, as a real iPhone alarm: it rings through silent mode and Focus.
/// Stopping it starts the briefing.
@MainActor
@Observable
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    var isOn: Bool = UserDefaults.standard.bool(forKey: "alarmOn")
    var hour: Int = UserDefaults.standard.object(forKey: "alarmHour") as? Int ?? 6
    var minute: Int = UserDefaults.standard.object(forKey: "alarmMinute") as? Int ?? 30
    var weekdaysOnly: Bool = UserDefaults.standard.bool(forKey: "alarmWeekdaysOnly")
    var errorMessage: String?

    private var alarmID: UUID? {
        get { UserDefaults.standard.string(forKey: "alarmID").flatMap(UUID.init(uuidString:)) }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: "alarmID") }
    }

    /// Saves the settings and replaces the scheduled alarm.
    func apply() async {
        errorMessage = nil
        let defaults = UserDefaults.standard
        defaults.set(isOn, forKey: "alarmOn")
        defaults.set(hour, forKey: "alarmHour")
        defaults.set(minute, forKey: "alarmMinute")
        defaults.set(weekdaysOnly, forKey: "alarmWeekdaysOnly")

        let manager = AlarmManager.shared
        if let alarmID {
            try? manager.cancel(id: alarmID)
            self.alarmID = nil
        }
        guard isOn else { return }

        do {
            if manager.authorizationState != .authorized {
                guard try await manager.requestAuthorization() == .authorized else {
                    errorMessage = "Allow alarms for Briefing in Settings → Apps → Briefing."
                    isOn = false
                    defaults.set(false, forKey: "alarmOn")
                    return
                }
            }
            let days: [Locale.Weekday] = weekdaysOnly
                ? [.monday, .tuesday, .wednesday, .thursday, .friday]
                : [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
            let schedule = Alarm.Schedule.relative(.init(
                time: .init(hour: hour, minute: minute),
                repeats: .weekly(days)
            ))
            let alert = AlarmPresentation.Alert(
                title: "Good morning ☀️",
                stopButton: AlarmButton(text: "Play briefing", textColor: .white, systemImageName: "play.fill")
            )
            let attributes = AlarmAttributes<BriefingAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                tintColor: Color(red: 0.914, green: 0.769, blue: 0.416)
            )
            let id = UUID()
            _ = try await manager.schedule(id: id, configuration: .alarm(
                schedule: schedule,
                attributes: attributes,
                stopIntent: PlayBriefingFromAlarmIntent()
            ))
            alarmID = id
        } catch {
            errorMessage = "The alarm couldn't be set: \(error.localizedDescription)"
        }
    }
}
