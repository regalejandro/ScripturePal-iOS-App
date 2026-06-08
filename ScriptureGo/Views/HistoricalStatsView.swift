//
//  HistoricalStatsView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 6/8/26.
//

import SwiftUI
import SwiftData

struct HistoricalStatsView: View {

    @Query private var records: [ReadingRecord]
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @StateObject private var bible = BibleManager()

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

    // MARK: - Body

    var body: some View {
        ZStack {
            themeManager.current.background
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {

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
                                theme: themeManager.current
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Reading History")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HistoricalStatsView()
            .environmentObject(ThemeManager())
    }
}
