//
//  ScriptureGoApp.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/17/25.
//

import SwiftUI
import SwiftData

@main
struct ScriptureGoApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    @AppStorage("themePreference")
    private var themePreference: ThemePreference = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
        .modelContainer(for: [ReadingRecord.self, CustomGroup.self])
    }
}


