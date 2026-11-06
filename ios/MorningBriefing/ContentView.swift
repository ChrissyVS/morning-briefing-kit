import SwiftUI

struct ContentView: View {
    @State private var player = BriefingPlayer.shared
    @State private var alarm = AlarmScheduler.shared
    @State private var showSettings = false
    @State private var showTranscript = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    playerCard
                    alarmCard
                    if let message = player.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Brand.sun)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
            .background(Brand.forest.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .tint(Brand.beige)
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showTranscript) { TranscriptView(episode: player.episode) }
            .onAppear {
                if BriefingSource.token == nil || BriefingSource.repo.isEmpty { showSettings = true }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("Cover")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 12)
            Text(player.episode?.title ?? "No briefing yet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Brand.beige)
            if let episode = player.episode, !isToday(episode.date) {
                Text("Today's briefing isn't downloaded yet. Tap play to get it.")
                    .font(.footnote)
                    .foregroundStyle(Brand.beige.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }

    private var playerCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Slider(
                    value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }),
                    in: 0...max(player.duration, 1)
                )
                .tint(Brand.sun)
                HStack {
                    Text(clock(player.currentTime))
                    Spacer()
                    Text("-" + clock(max(player.duration - player.currentTime, 0)))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(Brand.beige.opacity(0.7))
            }

            HStack(spacing: 44) {
                Button { player.skip(by: -15) } label: {
                    Image(systemName: "gobackward.15").font(.title)
                }
                Button { player.togglePlayPause() } label: {
                    ZStack {
                        Circle().fill(Brand.sun).frame(width: 76, height: 76)
                        if player.isLoading {
                            ProgressView().tint(Brand.forest)
                        } else {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(Brand.forest)
                        }
                    }
                }
                Button { player.skip(by: 15) } label: {
                    Image(systemName: "goforward.15").font(.title)
                }
            }
            .foregroundStyle(Brand.beige)

            HStack {
                Menu {
                    ForEach([0.9, 1.0, 1.1, 1.25, 1.5], id: \.self) { speed in
                        Button("\(speed, specifier: "%g")×") { player.rate = Float(speed) }
                    }
                } label: {
                    Label("\(Double(player.rate), specifier: "%g")×", systemImage: "speedometer")
                }
                Spacer()
                Button { showTranscript = true } label: {
                    Label("Read", systemImage: "text.alignleft")
                }
                .disabled(player.episode?.transcript.isEmpty ?? true)
            }
            .font(.subheadline)
            .tint(Brand.beige)
        }
        .padding(20)
        .background(Brand.beige.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private var alarmCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $alarm.isOn) {
                Label("Wake me with my briefing", systemImage: "alarm")
                    .font(.headline)
            }
            .tint(Brand.sun)

            if alarm.isOn {
                DatePicker("Time", selection: alarmTime, displayedComponents: .hourAndMinute)
                Toggle("Weekdays only", isOn: $alarm.weekdaysOnly).tint(Brand.sun)
                Text("A real alarm that rings even on silent. Tap **Play briefing** to stop it, and your briefing starts.")
                    .font(.footnote)
                    .foregroundStyle(Brand.beige.opacity(0.7))
            }
            if let message = alarm.errorMessage {
                Text(message).font(.footnote).foregroundStyle(Brand.sun)
            }
        }
        .foregroundStyle(Brand.beige)
        .padding(20)
        .background(Brand.beige.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .onChange(of: alarm.isOn) { Task { await alarm.apply() } }
        .onChange(of: alarm.weekdaysOnly) { Task { await alarm.apply() } }
    }

    private var alarmTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                alarm.hour = parts.hour ?? 6
                alarm.minute = parts.minute ?? 30
                Task { await alarm.apply() }
            }
        )
    }

    private func clock(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let s = Int(seconds.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func isToday(_ date: String) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now) == date
    }
}

struct TranscriptView: View {
    let episode: Episode?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(episode?.transcript ?? "")
                    .font(.body)
                    .lineSpacing(6)
                    .padding(20)
                    .textSelection(.enabled)
            }
            .navigationTitle(episode?.title ?? "Briefing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
