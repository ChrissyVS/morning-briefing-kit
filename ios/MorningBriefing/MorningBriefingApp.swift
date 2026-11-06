import SwiftUI

@main
struct MorningBriefingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

enum Brand {
    static let forest = Color(red: 0.122, green: 0.239, blue: 0.169)   // #1F3D2B
    static let beige = Color(red: 0.937, green: 0.902, blue: 0.824)    // #EFE6D2
    static let sun = Color(red: 0.914, green: 0.769, blue: 0.416)      // #E9C46A
}
