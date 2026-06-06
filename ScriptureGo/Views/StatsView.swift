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

    // MARK: - Derived stats

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private var thisYearRecords: [ReadingRecord] {
        records.filter { $0.year == currentYear }
    }

    /// Total chapter-log entries this year (counts re-reads)
    private var totalReadsThisYear: Int { thisYearRecords.count }

    /// Distinct (canonicalKey, chapter) pairs read this year
    private var uniqueChaptersThisYear: Int {
        Set(thisYearRecords.map { "\($0.canonicalKey)-\($0.chapter)" }).count
    }

    /// Total chapters available in the selected translation
    private var totalChaptersInTranslation: Int {
        bible.books(for: selectedTranslation).reduce(0) { $0 + $1.chapters }
    }

    /// 0.0 – 1.0 fraction of unique chapters read this year vs. translation total
    private var progressFraction: Double {
        guard totalChaptersInTranslation > 0 else { return 0 }
        return Double(uniqueChaptersThisYear) / Double(totalChaptersInTranslation)
    }

    /// Month (1-12) → read count for this year
    private var readsByMonth: [Int: Int] {
        var counts: [Int: Int] = [:]
        let cal = Calendar.current
        for record in thisYearRecords {
            let month = cal.component(.month, from: record.date)
            counts[month, default: 0] += 1
        }
        return counts
    }

    private var bestMonth: (name: String, count: Int)? {
        guard let top = readsByMonth.max(by: { $0.value < $1.value }), top.value > 0 else { return nil }
        let name = Calendar.current.monthSymbols[top.key - 1]
        return (name, top.value)
    }

    // MARK: - Grid lookup

    private var readCounts: [String: [Int: Int]] {
        var counts: [String: [Int: Int]] = [:]
        for record in records {
            counts[record.canonicalKey, default: [:]][record.chapter, default: 0] += 1
        }
        return counts
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                GeometryReader { geo in
                    let availableWidth = geo.size.width - 32
                    let squaresPerRow = max(1, Int((availableWidth + gap) / (squareSize + gap)))

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {

                            // ── Year stats card ──────────────────────────────
                            YearStatsCard(
                                year: currentYear,
                                totalReads: totalReadsThisYear,
                                uniqueChapters: uniqueChaptersThisYear,
                                totalChapters: totalChaptersInTranslation,
                                progressFraction: progressFraction,
                                bestMonth: bestMonth,
                                readsByMonth: readsByMonth,
                                accentColor: themeManager.current.accent,
                                primaryColor: themeManager.current.primary,
                                textPrimary: themeManager.current.textPrimary,
                                textSecondary: themeManager.current.textSecondary,
                                secondaryColor: themeManager.current.secondary,
                                cardBackground: themeManager.current.secondary.opacity(0.15),
                                cardBorder: themeManager.current.secondary.opacity(0.9)
                            )

                            // ── All-time grid ────────────────────────────────
                            Text("All-Time Reading Grid")
                                .font(.headline)
                                .foregroundColor(themeManager.current.textPrimary)
                                .padding(.top, 4)

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

// MARK: - YearStatsCard

private struct YearStatsCard: View {

    let year: Int
    let totalReads: Int
    let uniqueChapters: Int
    let totalChapters: Int
    let progressFraction: Double
    let bestMonth: (name: String, count: Int)?
    let readsByMonth: [Int: Int]

    let accentColor: Color
    let primaryColor: Color
    let textPrimary: Color
    let textSecondary: Color
    let secondaryColor: Color
    let cardBackground: Color
    let cardBorder: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("\(year, format: .number.grouping(.never)) Reading")
                .font(.headline)
                .foregroundColor(textPrimary)

            // ── Key numbers ──────────────────────────────────────────────────
            HStack(spacing: 0) {
                StatPill(
                    value: "\(totalReads)",
                    label: "Total Reads",
                    textPrimary: textPrimary,
                    textSecondary: textSecondary
                )
                Divider().frame(height: 36)
                StatPill(
                    value: "\(uniqueChapters) / \(totalChapters)",
                    label: "Chapters",
                    textPrimary: textPrimary,
                    textSecondary: textSecondary
                )
                Divider().frame(height: 36)
                StatPill(
                    value: String(format: "%.1f%%", progressFraction * 100),
                    label: "Coverage",
                    textPrimary: textPrimary,
                    textSecondary: textSecondary
                )
            }
            .frame(maxWidth: .infinity)

            // ── Progress bar ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(secondaryColor.opacity(0.3))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: geo.size.width * progressFraction, height: 8)
                            .animation(.easeOut(duration: 0.6), value: progressFraction)
                    }
                }
                .frame(height: 8)
            }

            // ── Best month ───────────────────────────────────────────────────
            if let best = bestMonth {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(accentColor)
                    Text("Best month: \(best.name) · \(best.count) chapter\(best.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }
            }

            Divider()

            // ── Monthly bar chart ────────────────────────────────────────────
            MonthlyBarChart(
                readsByMonth: readsByMonth,
                accentColor: accentColor,
                emptyColor: secondaryColor.opacity(0.25),
                labelColor: textSecondary
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - StatPill

private struct StatPill: View {
    let value: String
    let label: String
    let textPrimary: Color
    let textSecondary: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MonthlyBarChart

private struct MonthlyBarChart: View {

    let readsByMonth: [Int: Int]
    let accentColor: Color
    let emptyColor: Color
    let labelColor: Color

    private let monthAbbrevs = ["J","F","M","A","M","J","J","A","S","O","N","D"]
    private let maxBarHeight: CGFloat = 40

    private var maxCount: Int {
        readsByMonth.values.max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(1...12, id: \.self) { month in
                let count = readsByMonth[month] ?? 0
                let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0

                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(count > 0 ? accentColor.opacity(0.3 + 0.7 * fraction) : emptyColor)
                        .frame(height: max(4, maxBarHeight * fraction))
                        .animation(.easeOut(duration: 0.4), value: count)

                    Text(monthAbbrevs[month - 1])
                        .font(.system(size: 8))
                        .foregroundColor(labelColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: maxBarHeight + 16)
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

    private var rows: [[Int]] {
        let chapters = Array(1...max(1, book.chapters))
        return stride(from: 0, to: chapters.count, by: squaresPerRow).map {
            Array(chapters[$0 ..< min($0 + squaresPerRow, chapters.count)])
        }
    }

    private func squareColor(for chapter: Int) -> Color {
        switch chapterCounts[chapter] ?? 0 {
        case 0:   return emptyColor
        case 1:   return accentColor.opacity(0.25)
        case 2:   return accentColor.opacity(0.45)
        case 3:   return accentColor.opacity(0.65)
        case 4:   return accentColor.opacity(0.82)
        default:  return accentColor.opacity(1.0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.name)
                .font(.caption.weight(.semibold))
                .foregroundColor(nameColor)

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

// MARK: - Preview

#Preview {
    StatsView()
        .environmentObject(ThemeManager())
}
