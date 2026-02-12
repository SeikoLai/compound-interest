import SwiftUI

@main
/// EN: Struct definition for compound interest app.
/// ZH: Compound_InterestApp 的 struct 定義。
struct Compound_InterestApp: App {
    init() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-ui-testing") else { return }

        let defaults = UserDefaults.standard
        defaults.set("en", forKey: "appLanguage")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
