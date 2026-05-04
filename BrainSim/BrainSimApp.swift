// BrainSimApp.swift
// Entry point — sets a fixed minimum window size for macOS.

import SwiftUI

@main
struct BrainSimApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1100, height: 680)
        .windowResizability(.contentMinSize)
    }
}
