//
//  ScripturePalApp.swift
//  ScripturePal
//
//  Created by Alejandro Regalado on 11/17/25.
//

import SwiftUI
import SwiftData

@main
struct ScripturePalApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    @AppStorage("themePreference")
    private var themePreference: ThemePreference = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
        .modelContainer(for: [ReadingRecord.self, CustomGroup.self, CurrentlyReading.self, BookCompletion.self])
    }
}


