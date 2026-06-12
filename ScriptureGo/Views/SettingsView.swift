//
//  SettingsView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/21/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("selectedTradition") var selectedTradition = "Catholic"
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @AppStorage("selectedTheme") var selectedTheme = "parchment"
    @StateObject var bible = BibleManager()

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingClearAlert = false
    
    var availableTranslations: [String] {
        bible.data?.translations.keys.sorted() ?? []
    }
    
    var categorizedTranslations: [String: [String]] {
        let all = bible.data?.translations.keys.sorted() ?? []

        return Dictionary(
            grouping: all,
            by: { bible.tradition(of: $0) }
        )
    }

    
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    /* Tradition */
                    Section(header: Text("Tradtion")) {
                        ForEach(["Catholic", "Orthodox", "Protestant"], id: \.self) { tradition in
                            HStack{
                                Text(tradition)
                                Spacer()
                                if tradition == selectedTradition {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.current.accent)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTradition = tradition
                            }
                        }
                        
                    }
                    .foregroundColor(themeManager.current.textPrimary)

                    
                    /* Translations */
                    if let translations = categorizedTranslations[selectedTradition], !translations.isEmpty {
                        Section(header: Text("\(selectedTradition) Translations")) {
                            ForEach(translations, id: \.self) { translationID in
                                HStack {
                                    Text(translationID)
                                    Spacer()
                                    if translationID == selectedTranslation {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.current.accent)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTranslation = translationID
                                }
                            }
                        }
                        .foregroundColor(themeManager.current.textPrimary)

                    }
                    
                    /* Groups */
                    Section(header: Text("Groups")) {
                        NavigationLink {
                            GroupManagerView()
                        } label: {
                            Label("Manage Groups", systemImage: "folder")
                        }
                    }
                    .foregroundColor(themeManager.current.textPrimary)

                    /* Themes */
                    Section(header: Text("App Theme")) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Text(theme.rawValue.capitalized)
                                Spacer()
                                if theme.rawValue == selectedTheme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.current.accent)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    themeManager.setBaseTheme(
                                        theme,
                                        systemScheme: colorScheme
                                    )
                                }
                            }
                        }
                    }
                    .foregroundColor(themeManager.current.textPrimary)

                    /* Danger Zone */
                    Section (header: Text("Reading History")){
                        Button {
                            showingClearAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clear Reading History")
                                    .foregroundColor(themeManager.current.warning)
                                Spacer()
                            }
                        }
                    }
                    .foregroundColor(themeManager.current.textPrimary)
                    .alert("Clear Reading History?", isPresented: $showingClearAlert) {
                        Button("Clear", role: .destructive) {
                            try? modelContext.delete(model: ReadingRecord.self)
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will permanently delete all of your reading history and cannot be undone.")
                    }

                }
                .navigationTitle("Settings")
            }

        }
    }
}

enum ThemePreference: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}


#Preview {
    SettingsView()
        .environmentObject(ThemeManager())

}
