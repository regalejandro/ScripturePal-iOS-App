//
//  ContentView.swift
//  ScripturePal
//
//  Created by Alejandro Regalado on 11/17/25.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selection = 0
    @State private var reveal: RevealItem?

    var body: some View {
        ZStack {
            TabView(selection: $selection) {

                SelectorView(onReveal: { chapter, translation in
                    reveal = RevealItem(chapter: chapter, translation: translation)
                })
                    .tabItem {
                        Label("Select", systemImage: "rays")
                    }
                    .tag(0)

                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: selection == 1 ? "books.vertical.fill" : "books.vertical")
                            .environment(\.symbolVariants, .none)
                    }
                    .tag(1)

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: selection == 2 ? "chart.bar.fill" : "chart.bar")
                            .environment(\.symbolVariants, .none)
                    }
                    .tag(2)
            }
            .tint(themeManager.current.primary)

            // Full-screen chapter reveal rendered in-hierarchy
            if let reveal {
                ChapterRevealView(
                    chapter: reveal.chapter,
                    translation: reveal.translation,
                    onDismiss: { self.reveal = nil }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: reveal?.id)
        .onAppear {
            themeManager.apply(systemScheme: colorScheme)
        }
        .onChange(of: colorScheme) {
            themeManager.apply(systemScheme: colorScheme)
        }
    }
}

/// A pending chapter reveal presented over the whole app.
private struct RevealItem: Identifiable {
    let id = UUID()
    let chapter: ChapterPointer
    let translation: String
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
