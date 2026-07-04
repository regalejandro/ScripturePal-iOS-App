//
//  LibraryView.swift
//  ScripturePal
//
//  Created by Alejandro Regalado on 11/18/25.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - LibraryView

struct LibraryView: View {

    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims/Knox"
    @AppStorage("libraryTileSize") private var tileSizeRaw = LibraryTileSize.medium.rawValue

    @StateObject var bible = BibleManager()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CustomGroup.sortOrder), SortDescriptor(\CustomGroup.createdAt)]) private var customGroups: [CustomGroup]
    @Query private var currentlyReading: [CurrentlyReading]
    @Query private var records: [ReadingRecord]

    @State private var searchText = ""
    @State private var testamentFilter: TestamentFilter = .all
    @State private var groupFilter: GroupFilter = .all
    /// Set to a book's key when stopping its reading needs confirmation because
    /// the session already has logged progress.
    @State private var pendingStopKey: String?

    /// Horizontal inset on both edges of the grid.
    private let horizontalPadding: CGFloat = 16
    /// Spacing between tiles, both horizontally and vertically.
    private let spacing: CGFloat = 12
    /// Caps content width on wide/landscape screens so there's margin at the edges.
    private let maxContentWidth: CGFloat = 640

    /// iPad shows the title inside the (margined) content so it lines up with it.
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var tileSize: LibraryTileSize {
        LibraryTileSize(rawValue: tileSizeRaw) ?? .medium
    }

    private var books: [Book] { bible.books(for: selectedTranslation) }

    /// Books after applying testament + group filters and the search matcher.
    private var filteredBooks: [Book] {
        var result = books

        switch testamentFilter {
        case .all: break
        case .old: result = result.filter { isOldTestament($0) }
        case .new: result = result.filter { isNewTestament($0) }
        }

        switch groupFilter {
        case .all:
            break
        case .defaultGroup(let name):
            result = result.filter { $0.groups.contains(name) }
        case .custom(let uuid):
            if let group = customGroups.first(where: { $0.uuid == uuid }) {
                let keys = Set(group.bookKeys)
                result = result.filter { keys.contains($0.canonicalKey) }
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { BookSearch.matches(query: query, name: $0.name) }
        }

        return result
    }

    private var isFiltering: Bool {
        testamentFilter != .all || groupFilter != .all
    }

    private var currentlyReadingKeys: Set<String> {
        Set(currentlyReading.map { $0.canonicalKey })
    }

    /// Currently-read books that also match the active filters/search.
    private var currentlyReadingBooks: [Book] {
        filteredBooks.filter { currentlyReadingKeys.contains($0.canonicalKey) }
    }

    private func toggleCurrentlyReading(_ key: String) {
        if let existing = currentlyReading.first(where: { $0.canonicalKey == key }) {
            // If the session already has logged progress, confirm before
            // discarding it — the checkmarks disappear and a cover-to-cover
            // read won't be possible until every chapter is read again.
            if !sessionChapters(for: key).isEmpty {
                pendingStopKey = key
            } else {
                modelContext.delete(existing)
            }
        } else {
            modelContext.insert(CurrentlyReading(canonicalKey: key))
            Haptics.addedToCurrentlyReading()
        }
    }

    /// Chapters logged at or after the session start for the book with `key`.
    private func sessionChapters(for key: String) -> Set<Int> {
        guard let session = currentlyReading.first(where: { $0.canonicalKey == key }) else { return [] }
        return Set(records.filter { $0.canonicalKey == key && $0.date >= session.addedAt }.map { $0.chapter })
    }

    /// Display name for the book pending a stop-reading confirmation.
    private var pendingStopBookName: String {
        guard let key = pendingStopKey else { return "" }
        return books.first(where: { $0.canonicalKey == key })?.name ?? "this book"
    }

    private func confirmStopReading() {
        if let key = pendingStopKey,
           let existing = currentlyReading.first(where: { $0.canonicalKey == key }) {
            modelContext.delete(existing)
        }
        pendingStopKey = nil
    }

    private func isOldTestament(_ book: Book) -> Bool {
        ["OT", "OLD", "OLD TESTAMENT"]
            .contains(book.section.trimmingCharacters(in: .whitespaces).uppercased())
    }

    private func isNewTestament(_ book: Book) -> Bool {
        ["NT", "NEW", "NEW TESTAMENT"]
            .contains(book.section.trimmingCharacters(in: .whitespaces).uppercased())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                GeometryReader { geo in
                    // Fit as many tiles of the chosen size as the width allows.
                    // Clamp to 0 so the first (zero-width) layout pass can't
                    // produce a negative frame height. Cap to maxContentWidth so
                    // wide screens get edge margins instead of stretching.
                    let available = max(0, min(geo.size.width, maxContentWidth) - horizontalPadding * 2)
                    let columnCount = max(
                        1,
                        Int((available + spacing) / (tileSize.targetWidth + spacing))
                    )
                    let tileWidth = max(0, (available - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
                    let tileHeight = tileWidth * tileSize.aspectRatio

                    let columns = Array(
                        repeating: GridItem(.flexible(), spacing: spacing),
                        count: columnCount
                    )

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if isPad {
                                Text("Library")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(themeManager.current.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if !currentlyReadingBooks.isEmpty {
                                sectionHeader("Currently Reading")
                                bookGrid(currentlyReadingBooks, columns: columns, tileHeight: tileHeight)

                                sectionHeader("All Books")
                                bookGrid(filteredBooks, columns: columns, tileHeight: tileHeight)
                            } else {
                                bookGrid(filteredBooks, columns: columns, tileHeight: tileHeight)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 16)
                        .frame(maxWidth: maxContentWidth)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.25), value: tileSizeRaw)
                    }
                }
                .overlay {
                    if filteredBooks.isEmpty {
                        if !searchText.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            ContentUnavailableView(
                                "No Books",
                                systemImage: "book.closed",
                                description: Text("No books match the current filters.")
                            )
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search the library")
            .navigationTitle(isPad ? "" : "Library")
            .navigationBarTitleDisplayMode(isPad ? .inline : .automatic)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Testament", selection: $testamentFilter) {
                            ForEach(TestamentFilter.allCases) { filter in
                                Text(filter.label).tag(filter)
                            }
                        }
                        Picker("Group", selection: $groupFilter) {
                            Text("All Groups").tag(GroupFilter.all)

                            Section("Default Groups") {
                                ForEach(bible.groups(for: selectedTranslation), id: \.self) { group in
                                    Text(group).tag(GroupFilter.defaultGroup(group))
                                }
                            }

                            if !customGroups.isEmpty {
                                Section("Custom Groups") {
                                    ForEach(customGroups) { group in
                                        Text(group.name).tag(GroupFilter.custom(group.uuid))
                                    }
                                }
                            }
                        }
                        if isFiltering {
                            Button(role: .destructive) {
                                testamentFilter = .all
                                groupFilter = .all
                            } label: {
                                Label("Clear Filters", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: isFiltering
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                            .foregroundColor(themeManager.current.primary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Tile Size", selection: $tileSizeRaw) {
                            ForEach(LibraryTileSize.allCases) { size in
                                Label(size.label, systemImage: size.icon)
                                    .tag(size.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: tileSize.icon)
                            .foregroundColor(themeManager.current.primary)
                    }
                }
            }
            // Confirm ending a session that already has logged progress.
            .alert(
                "Stop reading \(pendingStopBookName)?",
                isPresented: Binding(
                    get: { pendingStopKey != nil },
                    set: { if !$0 { pendingStopKey = nil } }
                )
            ) {
                Button("Stop Reading", role: .destructive) { confirmStopReading() }
                Button("Keep Reading", role: .cancel) { pendingStopKey = nil }
            } message: {
                Text("All chapter checkmarks for this session will be removed. You won't be able to log a full reading of \(pendingStopBookName) unless you read every chapter again.")
            }
        }
    }

    // MARK: - Section helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(themeManager.current.textPrimary)
    }

    private func bookGrid(_ books: [Book], columns: [GridItem], tileHeight: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(books) { book in
                tileCell(book, tileHeight: tileHeight)
            }
        }
    }

    @ViewBuilder
    private func tileCell(_ book: Book, tileHeight: CGFloat) -> some View {
        let reading = currentlyReadingKeys.contains(book.canonicalKey)
        NavigationLink {
            BookDetailView(book: book)
        } label: {
            BookTile(
                book: book,
                size: tileSize,
                height: tileHeight,
                isCurrentlyReading: reading,
                theme: themeManager.current
            )
        }
        .buttonStyle(PressableTileStyle())
        .contextMenu {
            Button {
                toggleCurrentlyReading(book.canonicalKey)
            } label: {
                if reading {
                    Label("Reading", systemImage: "checkmark.circle.fill")
                } else {
                    Label("Reading", systemImage: "circle")
                }
            }
        }
    }
}

// MARK: - BookSearch

/// Lightweight "smart" library search.
///
/// Matches when the query is a prefix of the book name or of any word in it
/// (so "Ge" → Genesis, "cor" → 1 Corinthians, but a mid-word hit like "esis"
/// won't match). Misspellings are tolerated via a small Levenshtein distance
/// against equal-ish-length prefixes; fuzziness is disabled for 1–2 character
/// queries to avoid spurious matches.
enum BookSearch {

    static func matches(query: String, name: String) -> Bool {
        let q = normalize(query)
        guard !q.isEmpty else { return true }

        let n = normalize(name)
        var candidates = n.split(separator: " ").map(String.init)
        candidates.append(n) // whole name, for multi-word queries like "1 cor"

        for candidate in candidates {
            if candidate.hasPrefix(q) { return true }
            if q.count >= 3 && fuzzyPrefixMatch(q, candidate) { return true }
        }
        return false
    }

    private static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True if `query` is within an edit-distance tolerance of a same-length-ish
    /// prefix of `candidate`.
    private static func fuzzyPrefixMatch(_ query: String, _ candidate: String) -> Bool {
        let tolerance = query.count <= 5 ? 1 : 2
        let q = Array(query)
        let c = Array(candidate)

        let lower = max(1, q.count - tolerance)
        let upper = min(c.count, q.count + tolerance)
        guard lower <= upper else { return false }

        for length in lower...upper {
            if levenshtein(q, Array(c[0..<length])) <= tolerance { return true }
        }
        return false
    }

    private static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,      // deletion
                    current[j - 1] + 1,   // insertion
                    previous[j - 1] + cost // substitution
                )
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}

// MARK: - BookTile

private struct BookTile: View {

    let book: Book
    let size: LibraryTileSize
    let height: CGFloat
    let isCurrentlyReading: Bool
    let theme: Theme

    var body: some View {
        VStack(spacing: size.innerSpacing) {

            Image(systemName: isCurrentlyReading ? "book.closed.circle" : "book.closed.fill")
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(theme.primary)

            Text(book.name)
                .font(.system(size: size.nameFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Text("\(book.chapters) \(book.chapters == 1 ? "chapter" : "chapters")")
                .font(.system(size: size.subtitleFontSize, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondary.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.secondary.opacity(0.9), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            // Slim accent cap for a touch of personality.
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent.opacity(0.8))
                .frame(width: 28, height: 4)
                .padding(.top, 8)
        }
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - PressableTileStyle

/// Gives the tiles a subtle, springy press animation so they read as tappable.
private struct PressableTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - TestamentFilter

/// Testament filter options for the library.
enum TestamentFilter: String, CaseIterable, Identifiable {
    case all
    case old
    case new

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Testaments"
        case .old: return "Old Testament"
        case .new: return "New Testament"
        }
    }
}

// MARK: - GroupFilter

/// Library group filter: all books, a default (built-in) group, or a custom group.
enum GroupFilter: Hashable {
    case all
    case defaultGroup(String)
    case custom(UUID)
}

// MARK: - LibraryTileSize

/// The three tile sizes the user can choose from. `targetWidth` is the minimum
/// width a tile wants; the grid fits as many of that width as possible per row,
/// so phones land on ~2 / ~3 / ~4 columns while iPads fit proportionally more.
enum LibraryTileSize: String, CaseIterable, Identifiable {
    case large
    case medium
    case small

    var id: String { rawValue }

    var label: String {
        switch self {
        case .large:  return "Large"
        case .medium: return "Medium"
        case .small:  return "Small"
        }
    }

    var icon: String {
        switch self {
        case .large:  return "square.grid.2x2"
        case .medium: return "square.grid.3x2"
        case .small:  return "square.grid.4x3.fill"
        }
    }

    var targetWidth: CGFloat {
        switch self {
        case .large:  return 165
        case .medium: return 108
        case .small:  return 78
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .large:  return 1.15
        case .medium: return 1.2
        case .small:  return 1.25
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .large:  return 30
        case .medium: return 23
        case .small:  return 17
        }
    }

    var nameFontSize: CGFloat {
        switch self {
        case .large:  return 18
        case .medium: return 15
        case .small:  return 12
        }
    }

    var subtitleFontSize: CGFloat {
        switch self {
        case .large:  return 12
        case .medium: return 10.5
        case .small:  return 9
        }
    }

    var innerSpacing: CGFloat {
        switch self {
        case .large:  return 8
        case .medium: return 6
        case .small:  return 4
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .environmentObject(ThemeManager())
}
