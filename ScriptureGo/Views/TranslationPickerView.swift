//
//  TranslationPickerView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/18/25.
//

import SwiftUI

struct TranslationPickerView: View {
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @StateObject var bible = BibleManager()
    
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            VStack {

                List(bible.books(for: selectedTranslation)) { book in
                    NavigationLink(book.name) {
                        BookDetailView(book: book)
                    }
                    .foregroundColor(themeManager.current.textPrimary)
                }
            }
            .navigationTitle("Books")
        }
    }
}


#Preview {
    TranslationPickerView()
        .environmentObject(ThemeManager())

}
