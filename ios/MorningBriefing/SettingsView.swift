import SwiftUI

/// Where the briefing comes from: the GitHub repository and a read-only key.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("repo") private var repo = ""
    @State private var token = BriefingSource.token ?? ""
    @State private var status: String?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("your-github-name/my-morning-briefing", text: $repo)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("github_pat_…", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Your briefing on GitHub")
                } footer: {
                    Text("Use a fine-grained GitHub key with read-only access to this one repository. It's stored in your iPhone's Keychain.")
                }

                Section {
                    Button {
                        Task { await test() }
                    } label: {
                        HStack {
                            Text("Save and test")
                            if testing { Spacer(); ProgressView() }
                        }
                    }
                    if let status {
                        Text(status).font(.footnote)
                    }
                }

                Section("Use with Shortcuts") {
                    Text("The action **Play Morning Briefing** is in the Shortcuts app. You can also say \"Hey Siri, play my Briefing\".")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") {
                    save()
                    dismiss()
                }
            }
        }
    }

    private func save() {
        repo = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        BriefingSource.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func test() async {
        save()
        testing = true
        defer { testing = false }
        do {
            let date = String(decoding: try await BriefingSource.fetch("date.txt"), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            status = "✅ Connected. Newest briefing: \(date)"
        } catch {
            status = "❌ " + error.localizedDescription
        }
    }
}
