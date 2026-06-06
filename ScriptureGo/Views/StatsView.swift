//
//  StatsView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 6/5/26.
//

import SwiftUI
import SwiftData

struct StatsView: View {

    @Query private var records: [ReadingRecord]
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @StateObject private var bible = BibleManager()

    // Grid dimensions
    private let squareSize: CGFloat = 12
    private let gap: CGFloat = 3

    // Collapses all records into a fast lookup: canonicalKey → chapter → read count
    private var readCounts: [String: [Int: Int]] {
        var counts: [String: [Int: Int]] = [:]
        for record in records {
            counts[record.canonicalKey, default: [:]][record.chapter, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                GeometryReader { geo in
                    // 32pt total horizontal padding (16 each side)
                    let availableWidth = geo.size.width - 32
                    let squaresPerRow = max(1, Int((availableWidth + gap) / (squareSize + gap)))

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(bible.books(for: selectedTranslation)) { book in
                                BookGridRow(
                                    book: book,
                                    chapterCounts: readCounts[book.canonicalKey] ?? [:],
                                    squaresPerRow: squaresPerRow,
                                    squareSize: squareSize,
                                    gap: gap,
                                    accentColor: themeManager.current.accent,
                                    emptyColor: themeManager.current.secondary.opacity(0.25),
                                    nameColor: themeManager.current.textSecondary
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Reading Stats")
        }
    }
}

// MARK: - BookGridRow

private struct BookGridRow: View {

    let book: Book
    let chapterCounts: [Int: Int]
    let squaresPerRow: Int
    let squareSize: CGFloat
    let gap: CGFloat
    let accentColor: Color
    let emptyColor: Color
    let nameColor: Color

    // Chapters 1...book.chapters split into rows of squaresPerRow
    private var rows: [[Int]] {
        let chapters = Array(1...max(1, book.chapters))
        return stride(from: 0, to: chapters.count, by: squaresPerRow).map {
            Array(chapters[$0 ..< min($0 + squaresPerRow, chapters.count)])
        }
    }

    private func squareColor(for chapter: Int) -> Color {
        switch chapterCounts[chapter] ?? 0 {
        case 0:       return emptyColor
        case 1:       return accentColor.opacity(0.25)
        case 2:       return accentColor.opacity(0.45)
        case 3:       return accentColor.opacity(0.65)
        case 4:       return accentColor.opacity(0.82)
        default:      return accentColor.opacity(1.0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Book name header
            Text(book.name)
                .font(.caption.weight(.semibold))
                .foregroundColor(nameColor)

            // Chapter squares — one HStack per row, all flush-left
            VStack(alignment: .leading, spacing: gap) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: gap) {
                        ForEach(rows[rowIndex], id: \.self) { chapter in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(squareColor(for: chapter))
                                .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(ThemeManager())
}
