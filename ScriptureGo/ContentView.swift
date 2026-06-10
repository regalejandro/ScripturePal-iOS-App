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

    
    var body: some View {
            
        TabView {
            
            SelectorView()
                .tabItem {
                    Label("Select", systemImage: "rays")
                }
        
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
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
