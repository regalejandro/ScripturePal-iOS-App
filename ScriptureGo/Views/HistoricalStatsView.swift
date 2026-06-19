//
//  HistoricalStatsView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 6/8/26.
//

import SwiftUI
import SwiftData
import UIKit

struct HistoricalStatsView: View {

    @Query private var records: [ReadingRecord]
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @StateObject private var bible = BibleManager()

    /// iPad shows the title inside the (margined) content so it lines up with it.
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // MARK: - All-time computed stats

    private var totalChaptersInTranslation: Int {
        bible.books(for: selectedTranslation).reduce(0) { $0 + $1.chapters }
    }

    private var totalReadsAllTime: Int { records.count }

    private var uniqueChaptersAllTime: Int {
        Set(records.map { "\($0.canonicalKey)-\($0.chapter)" }).count
    }

    private var allTimeProgressFraction: Double {
        guard totalChaptersInTranslation > 0 else { return 0 }
        return Double(uniqueChaptersAllTime) / Double(totalChaptersInTranslation)
    }

    /// Year → total reads that year
    private var readsByYear: [Int: Int] {
        var counts: [Int: Int] = [:]
        for record in records {
            counts[record.year, default: 0] += 1
        }
        return counts
    }

    /// All calendar years that appear in the data, newest first
    private var activeYears: [Int] {
        readsByYear.keys.sorted(by: >)
    }

    private var bestYear: (year: Int, count: Int)? {
        guard let top = readsByYear.max(by: { $0.value < $1.value }), top.value > 0 else { return nil }
        return (top.key, top.value)
    }

    /// canonicalKey → total reads across all time
    private var readsByCanonicalKey: [String: Int] {
        var counts: [String: Int] = [:]
        for record in records {
            counts[record.canonicalKey, default: 0] += 1
        }
        return counts
    }

    /// The translation book name for the most-logged canonicalKey
    private var mostReadBook: (name: String, count: Int)? {
        guard let top = readsByCanonicalKey.max(by: { $0.value < $1.value }), top.value > 0 else { return nil }
        let name = bible.books(for: selectedTranslation)
            .first(where: { $0.canonicalKey == top.key })?.name ?? top.key
        return (name, top.value)
    }

    // MARK: - Testament progress

    private func isOldTestament(_ section: String) -> Bool {
        ["OT", "OLD", "OLD TESTAMENT"]
            .contains(section.trimmingCharacters(in: .whitespaces).uppercased())
    }

    /// Unique chapters read out of total chapters, split by testament.
    private var testamentProgress: (old: (read: Int, total: Int), new: (read: Int, total: Int)) {
        let books = bible.books(for: selectedTranslation)

        var oldTotal = 0, newTotal = 0
        var oldKeys = Set<String>(), newKeys = Set<String>()
        for book in books {
            if isOldTestament(book.section) {
                oldTotal += book.chapters
                oldKeys.insert(book.canonicalKey)
            } else {
                newTotal += book.chapters
                newKeys.insert(book.canonicalKey)
            }
        }

        var oldRead = Set<String>(), newRead = Set<String>()
        for record in records {
            let id = "\(record.canonicalKey)-\(record.chapter)"
            if oldKeys.contains(record.canonicalKey) {
                oldRead.insert(id)
            } else if newKeys.contains(record.canonicalKey) {
                newRead.insert(id)
            }
        }

        return ((oldRead.count, oldTotal), (newRead.count, newTotal))
    }

    // MARK: - Per-year helpers

    private func records(for year: Int) -> [ReadingRecord] {
        records.filter { $0.year == year }
    }

    private func totalReads(for year: Int) -> Int {
        records(for: year).count
    }

    private func uniqueChapters(for year: Int) -> Int {
        Set(records(for: year).map { "\($0.canonicalKey)-\($0.chapter)" }).count
    }

    private func progressFraction(for year: Int) -> Double {
        guard totalChaptersInTranslation > 0 else { return 0 }
        return Double(uniqueChapters(for: year)) / Double(totalChaptersInTranslation)
    }

    private func readsByMonth(for year: Int) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for record in records(for: year) {
            let month = Calendar.current.component(.month, from: record.date)
            counts[month, default: 0] += 1
        }
        return counts
    }

    private func bestMonth(for year: Int) -> (name: String, count: Int)? {
        let byMonth = readsByMonth(for: year)
        guard let top = byMonth.max(by: { $0.value < $1.value }), top.value > 0 else { return nil }
        return (Calendar.current.monthSymbols[top.key - 1], top.value)
    }

    /// Unique chapters read that year out of total chapters, split by testament.
    private func testamentProgress(for year: Int) -> (old: (read: Int, total: Int), new: (read: Int, total: Int)) {
        let books = bible.books(for: selectedTranslation)

        var oldTotal = 0, newTotal = 0
        var oldKeys = Set<String>(), newKeys = Set<String>()
        for book in books {
            if isOldTestament(book.section) {
                oldTotal += book.chapters
                oldKeys.insert(book.canonicalKey)
            } else {
                newTotal += book.chapters
                newKeys.insert(book.canonicalKey)
            }
        }

        var oldRead = Set<String>(), newRead = Set<String>()
        for record in records(for: year) {
            let id = "\(record.canonicalKey)-\(record.chapter)"
            if oldKeys.contains(record.canonicalKey) {
                oldRead.insert(id)
            } else if newKeys.contains(record.canonicalKey) {
                newRead.insert(id)
            }
        }

        return ((oldRead.count, oldTotal), (newRead.count, newTotal))
    }

    // MARK: - Reading log helpers

    /// canonicalKey → display book name for the current translation.
    private var bookNameByKey: [String: String] {
        Dictionary(
            bible.books(for: selectedTranslation).map { ($0.canonicalKey, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func bookName(_ key: String) -> String {
        bookNameByKey[key] ?? key
    }

    // MARK: - Reading log section

    @ViewBuilder
    private var readingLogSection: some View {
        if !records.isEmpty {
            Divider()
                .padding(.vertical, 4)

            Text("Reading Log")
                .font(.headline)
                .foregroundColor(themeManager.current.textPrimary)

            ReadingLogView(
                records: records,
                bookName: bookName,
                theme: themeManager.current
            )
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            themeManager.current.background
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {

                    if isPad {
                        Text("Reading History")
                            .font(.largeTitle.bold())
                            .foregroundColor(themeManager.current.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // ── All-time card ────────────────────────────────────────
                    AllTimeStatsCard(
                        totalReads: totalReadsAllTime,
                        uniqueChapters: uniqueChaptersAllTime,
                        totalChapters: totalChaptersInTranslation,
                        progressFraction: allTimeProgressFraction,
                        bestYear: bestYear,
                        mostReadBook: mostReadBook,
                        yearsActive: activeYears.count,
                        readsByYear: readsByYear,
                        oldTestament: testamentProgress.old,
                        newTestament: testamentProgress.new,
                        theme: themeManager.current
                    )

                    // ── Per-year cards ───────────────────────────────────────
                    if activeYears.isEmpty {
                        Text("No reading history yet.")
                            .font(.subheadline)
                            .foregroundColor(themeManager.current.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 32)
                    } else {
                        ForEach(activeYears, id: \.self) { year in
                            YearStatsCard(
                                year: year,
                                totalReads: totalReads(for: year),
                                uniqueChapters: uniqueChapters(for: year),
                                totalChapters: totalChaptersInTranslation,
                                progressFraction: progressFraction(for: year),
                                bestMonth: bestMonth(for: year),
                                readsByMonth: readsByMonth(for: year),
                                oldTestament: testamentProgress(for: year).old,
                                newTestament: testamentProgress(for: year).new,
                                theme: themeManager.current
                            )
                        }

                        readingLogSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isPad ? "" : "Reading History")
        .navigationBarTitleDisplayMode(isPad ? .inline : .large)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HistoricalStatsView()
            .environmentObject(ThemeManager())
    }
}
