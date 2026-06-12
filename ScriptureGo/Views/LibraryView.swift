//
//  LibraryView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/18/25.
//

import SwiftUI

// MARK: - LibraryView

struct LibraryView: View {

    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @AppStorage("libraryTileSize") private var tileSizeRaw = LibraryTileSize.medium.rawValue

    @StateObject var bible = BibleManager()
    @EnvironmentObject var themeManager: ThemeManager

    @State private var searchText = ""

    /// Horizontal inset on both edges of the grid.
    private let horizontalPadding: CGFloat = 16
    /// Spacing between tiles, both horizontally and vertically.
    private let spacing: CGFloat = 12

    private var tileSize: LibraryTileSize {
        LibraryTileSize(rawValue: tileSizeRaw) ?? .medium
    }

    private var books: [Book] { bible.books(for: selectedTranslation) }

    /// Books filtered by the smart search matcher (all books when not searching).
    private var filteredBooks: [Book] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return books }
        return books.filter { BookSearch.matches(query: query, name: $0.name) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                GeometryReader { geo in
                    // Fit as many tiles of the chosen size as the width allows.
                    // Clamp to 0 so the first (zero-width) layout pass can't
                    // produce a negative frame height.
                    let available = max(0, geo.size.width - horizontalPadding * 2)
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
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(filteredBooks) { book in
                                NavigationLink {
                                    BookDetailView(book: book)
                                } label: {
                                    BookTile(
                                        book: book,
                                        size: tileSize,
                                        height: tileHeight,
                                        theme: themeManager.current
                                    )
                                }
                                .buttonStyle(PressableTileStyle())
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 16)
                        .animation(.easeInOut(duration: 0.25), value: tileSizeRaw)
                    }
                }
                .overlay {
                    if filteredBooks.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search the library")
            .navigationTitle("Library")
            .toolbar {
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
    let theme: Theme

    var body: some View {
        VStack(spacing: size.innerSpacing) {

            Image(systemName: "book.closed.fill")
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
