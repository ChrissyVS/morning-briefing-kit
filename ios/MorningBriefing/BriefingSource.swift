import Foundation
import Security

/// One day's briefing, downloaded to the phone.
struct Episode: Equatable {
    let date: String        // "2026-11-06"
    let audioURL: URL
    let transcript: String

    var title: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let day = parser.date(from: date) else { return date }
        let out = DateFormatter()
        out.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return out.string(from: day)
    }
}

enum BriefingError: LocalizedError {
    case notSetUp
    case github(Int)

    var errorDescription: String? {
        switch self {
        case .notSetUp:
            return "Add your GitHub repository and key in Settings first."
        case .github(let code) where [401, 403, 404].contains(code):
            return "GitHub didn't accept the key (error \(code)). Check the key and repository in Settings."
        case .github(let code):
            return "GitHub error \(code). Try again in a minute."
        }
    }
}

/// Fetches the briefing that GitHub publishes to the `audio` branch every morning.
enum BriefingSource {
    static var repo: String {
        (UserDefaults.standard.string(forKey: "repo") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var token: String? {
        get { Keychain.read("github-token") }
        set { Keychain.write("github-token", newValue) }
    }

    private static var folder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func fetch(_ path: String) async throws -> Data {
        guard let token, !token.isEmpty, repo.contains("/") else { throw BriefingError.notSetUp }
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)?ref=audio")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.raw", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 60
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw BriefingError.github(code) }
        return data
    }

    /// Today's briefing: downloaded once, then played from the phone. Offline, the newest saved one.
    static func latest() async throws -> Episode {
        do {
            let date = String(decoding: try await fetch("date.txt"), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let audio = folder.appendingPathComponent("briefing-\(date).mp3")
            let text = folder.appendingPathComponent("briefing-\(date).txt")
            if !FileManager.default.fileExists(atPath: audio.path) {
                let mp3 = try await fetch("latest.mp3")
                let script = (try? await fetch("latest.txt")) ?? Data()
                try script.write(to: text, options: .atomic)
                try mp3.write(to: audio, options: .atomic)
                removeOld(keeping: date)
            }
            return Episode(date: date, audioURL: audio, transcript: (try? String(contentsOf: text, encoding: .utf8)) ?? "")
        } catch {
            if let saved = newestSaved() { return saved }
            throw error
        }
    }

    static func newestSaved() -> Episode? {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        guard let audio = files.filter({ $0.pathExtension == "mp3" }).map(\.lastPathComponent).sorted().last else {
            return nil
        }
        let date = String(audio.dropFirst("briefing-".count).dropLast(".mp3".count))
        let text = folder.appendingPathComponent("briefing-\(date).txt")
        return Episode(date: date, audioURL: folder.appendingPathComponent(audio),
                       transcript: (try? String(contentsOf: text, encoding: .utf8)) ?? "")
    }

    /// Keeps the phone tidy: only the newest few briefings stay.
    private static func removeOld(keeping date: String) {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        let briefings = files.filter { $0.lastPathComponent.hasPrefix("briefing-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for old in briefings.dropFirst(6) { try? FileManager.default.removeItem(at: old) }
    }
}

/// The GitHub key lives in the iPhone's Keychain, not in plain settings.
enum Keychain {
    private static let service = Bundle.main.bundleIdentifier ?? "morningbriefing"

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: true]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ key: String, _ value: String?) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        guard let value, !value.isEmpty else { return }
        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        // Readable after the first unlock since boot, so the alarm can fetch it on a locked phone.
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(item as CFDictionary, nil)
    }
}
