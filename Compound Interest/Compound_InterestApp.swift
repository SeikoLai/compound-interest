//
//  Compound_InterestApp.swift
//  Compound Interest
//
//  Created by Sam Lai on 2026/2/2.
//

import SwiftUI

@main
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
