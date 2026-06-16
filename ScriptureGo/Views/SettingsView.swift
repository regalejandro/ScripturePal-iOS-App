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
                    Section(
                        header: Text("Tradition"),
                        footer: Text("Tradition selection is purely for determining which translations are presented to you.")
                    ) {
                        Picker("Tradition", selection: $selectedTradition) {
                            ForEach(["Catholic", "Orthodox", "Protestant"], id: \.self) { tradition in
                                Text(tradition).tag(tradition)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .foregroundColor(themeManager.current.textPrimary)

                    /* Translation */
                    if let translations = categorizedTranslations[selectedTradition], !translations.isEmpty {
                        Section(
                            header: Text("\(selectedTradition) Translations"),
                            footer: Text(translationFooter)
                        ) {
                            Picker("Translation", selection: $selectedTranslation) {
                                ForEach(translations, id: \.self) { translationID in
                                    Text(translationID).tag(translationID)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .foregroundColor(themeManager.current.textPrimary)
                    }

                    /* Groups */
                    Section(header: Text("Groups")) {
                        NavigationLink {
                            GroupManagerView()
                        } label: {
                            Label("Manage Groups", systemImage: "rectangle.3.group")
                        }
                    }
                    .foregroundColor(themeManager.current.textPrimary)

                    /* Themes */
                    Section(header: Text("App Theme")) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack(spacing: 10) {
                                Text(theme.displayName)
                                    .frame(width: 120, alignment: .leading)
                                    .lineLimit(1)
                                ThemeSwatch(appTheme: theme, colorScheme: colorScheme)
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
                // Keep the translation consistent with the chosen tradition:
                // selecting a tradition snaps to its first translation.
                .onChange(of: selectedTradition) { _, newTradition in
                    if let first = categorizedTranslations[newTradition]?.first,
                       !(categorizedTranslations[newTradition]?.contains(selectedTranslation) ?? false) {
                        selectedTranslation = first
                    }
                }
            }

        }
    }

    /// Disclaimer shown beneath the translation picker.
    private var translationFooter: String {
        let base = "Different translations may contain different books, number chapters differently, and contain a different cannon."
        if selectedTradition == "Protestant" {
            return base + " The vast majority of English protestant translations share the same book names and chapter numbering."
        }
        return base
    }
}

// MARK: - ThemeSwatch

/// A connected strip of a theme's representative colors, shown beside its name.
private struct ThemeSwatch: View {
    let appTheme: AppTheme
    let colorScheme: ColorScheme

    private var colors: [Color] {
        let theme = (colorScheme == .dark ? appTheme.dark : appTheme.light).theme
        return [theme.primary, theme.secondary, theme.background, theme.accent, theme.warning]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Rectangle()
                    .fill(color)
                    .frame(width: 14, height: 16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
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
