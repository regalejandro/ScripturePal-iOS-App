//
//  BookDetailView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/18/25.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    let book: Book

    @State private var selectedChapter: Int = 1
    @State private var showingReadAlert = false

    var body: some View {
        Form {
            Section("Info") {
                HStack {
                    Text("Name")
                        .foregroundColor(themeManager.current.textPrimary)
                    Spacer()
                    Text(book.name)
                        .foregroundColor(themeManager.current.textSecondary)
                }
                
                
                HStack {
                    Text("Chapters")
                        .foregroundColor(themeManager.current.textPrimary)
                    Spacer()
                    Text("\(book.chapters)")
                        .foregroundColor(themeManager.current.textSecondary)

                }
                HStack {
                    Text("Section")
                        .foregroundColor(themeManager.current.textPrimary)
                    Spacer()
                    Text(book.section)
                        .foregroundColor(themeManager.current.textSecondary)

                }
            }

            Section("Groups") {
                ForEach(book.groups, id: \.self) { group in
                    Text(group)
                        .foregroundColor(themeManager.current.textPrimary)
                }
            }

            Section("Log Reading") {

                Picker("Chapter", selection: $selectedChapter) {
                    ForEach(1...book.chapters, id: \.self) { chapter in
                        Text("Chapter \(chapter)").tag(chapter)
                    }
                }
                .foregroundColor(themeManager.current.textPrimary)

                HStack {
                    Text("Times Read")
                        .foregroundColor(themeManager.current.textPrimary)
                    Spacer()
                    ChapterReadCount(canonicalKey: book.canonicalKey, chapter: selectedChapter)
                        .foregroundColor(themeManager.current.textSecondary)
                }
                
                Button {
                    let record = ReadingRecord(
                        canonicalKey: book.canonicalKey,
                        chapter: selectedChapter
                    )
                    modelContext.insert(record)
                    showingReadAlert = true
                } label: {
                    Label("Log Reading", systemImage: "checkmark.circle")
                        .foregroundColor(themeManager.current.accent)
                }
                .alert("Reading of \(book.name) \(selectedChapter)  has been logged for today's date.", isPresented: $showingReadAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
        }
        .navigationTitle(book.name)
    }
}

// Isolated view so @Query can react to dynamic canonicalKey + chapter values.
private struct ChapterReadCount: View {

    @Query private var records: [ReadingRecord]

    init(canonicalKey: String, chapter: Int) {
        _records = Query(filter: #Predicate<ReadingRecord> { record in
            record.canonicalKey == canonicalKey && record.chapter == chapter
        })
    }

    var body: some View {
        Text("\(records.count)")
    }
}

#Preview {
    BookDetailView(book: Book.init(id: 1, name: "Genesis", chapters: 50, groups: ["A", "B"], section: "Old Testament", canonicalKey: "genesis"))
        .environmentObject(ThemeManager())

}
