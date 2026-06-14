//
//  ContentView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/17/25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selection = 0


    var body: some View {
            
        TabView(selection: $selection) {

            SelectorView()
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
        .onAppear {
            themeManager.apply(systemScheme: colorScheme)
        }
        .onChange(of: colorScheme) {
            themeManager.apply(systemScheme: colorScheme)
        }
        
    }

    
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
