//
//  DataLoad.swift
//  ScripturePal
//
//  Created by Alejandro Regalado on 11/18/25.
//

import Foundation
import Combine

class BibleManager: ObservableObject {
    @Published var data: BibleData?

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "booknames", withExtension: "json") else {
            print("JSON not found")
            return
        }

        do {
            let jsonData = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(BibleData.self, from: jsonData)
            self.data = decoded
        } catch {
            print("Error loading JSON:", error)
        }
    }

    func books(for translation: String) -> [Book] {
        data?.translations[translation]?.books ?? []
    }
    
    func tradition(of translationID: String) -> String {
        data?.translations[translationID]?.tradition ?? "Other"
    }

    /// Manual display-order ranking, since "most standard" isn't always
    /// not listed here just falls back to alphabetical order, after the
    /// ranked ones.
    private static let translationDisplayOrder: [String: Int] = [
        "Douay-Rheims/Knox": 0,
        "NABRE/NRSV-CE": 1,
        "RSVCE": 2,
        "Jerusalem Bible/RNJB": 3,
        "Standard Protestant Canon": 0,
        "OSB": 0,
        "NETS": 1
    ]

    /// Sorts translation names for display: ranked ones in their preferred
    /// order, then any unranked ones alphabetically.
    func sortedTranslationNames(_ names: [String]) -> [String] {
        names.sorted { a, b in
            let rankA = Self.translationDisplayOrder[a]
            let rankB = Self.translationDisplayOrder[b]
            switch (rankA, rankB) {
            case let (rankA?, rankB?): return rankA < rankB
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): return a < b
            }
        }
    }

    func randomChapter(
        for translation: String,
        selectedGroups: [String],
        groupMode: String,
        customGroupKeys: Set<String> = []
    ) -> ChapterPointer? {

        // Get filtered books
        let books = filteredBooks(
            for: translation,
            matchingGroups: selectedGroups,
            groupMode: groupMode,
            customGroupKeys: customGroupKeys
        )
        guard books.isEmpty == false else { return nil }
        
        // Count total chapters
        let totalChapters = books.reduce(0) { $0 + $1.chapters }
        guard totalChapters > 0 else { return nil }

        // Pick uniformly across all chapters
        let randomIndex = Int.random(in: 1...totalChapters)
        var runningTotal = 0

        for book in books {
            let nextTotal = runningTotal + book.chapters
            if randomIndex <= nextTotal {
                let chapterNumber = randomIndex - runningTotal
                return ChapterPointer(
                    bookID: book.id,
                    bookName: book.name,
                    chapter: chapterNumber,
                    canonicalKey: book.canonicalKey
                )
            }
            runningTotal = nextTotal
        }

        return nil
    }


    func groups(for translation: String) -> [String] {
        let books = data?.translations[translation]?.books ?? []

        var seen = Set<String>()
        var orderedGroups: [String] = []

        for book in books {
            for group in book.groups {
                if !seen.contains(group) {
                    seen.insert(group)
                    orderedGroups.append(group)
                }
            }
        }

        return orderedGroups
    }

    func filteredBooks(
        for translation: String,
        matchingGroups groups: [String],
        groupMode: String,
        customGroupKeys: Set<String> = []
    ) -> [Book] {

        let allBooks = books(for: translation)

        if groupMode == "all" {
            return allBooks
        }

        // In custom mode a book qualifies if it belongs to a selected default
        // group OR is a member of a selected custom group.
        return allBooks.filter { book in
            !Set(book.groups).isDisjoint(with: groups)
            || customGroupKeys.contains(book.canonicalKey)
        }
    }

    
}

