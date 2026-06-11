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

    /// Whether the full reading log is expanded beyond the default 7 days.
    @State private var showAllReads = false

    /// Number of most-recent logged dates shown before "Show All".
    private let defaultDayCount = 7

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

    /// All logged reads grouped by calendar day, newest day first and newest
    /// read first within each day.
    private var recordsByDay: [(day: Date, records: [ReadingRecord])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: records) { cal.startOfDay(for: $0.date) }
        return groups
            .map { (day: $0.key, records: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    /// The earliest date anything was logged, for the "Since …" subcaption.
    private var earliestDate: Date? {
        records.map(\.date).min()
    }

    // MARK: - Reading log section

    @ViewBuilder
    private var readingLogSection: some View {
        if !recordsByDay.isEmpty {
            let theme = themeManager.current
            let allDays = recordsByDay
            let visibleDays = showAllReads ? allDays : Array(allDays.prefix(defaultDayCount))

            Divider()
                .padding(.vertical, 4)

            Text("Reading Log")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            ForEach(visibleDays, id: \.day) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.day.formatted(date: .long, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textSecondary)

                    ForEach(group.records, id: \.persistentModelID) { record in
                        LoggedReadCard(
                            bookName: bookName(record.canonicalKey),
                            chapter: record.chapter,
                            theme: theme
                        )
                    }
                }
                .padding(.top, 4)
            }

            // Show All / Show Less toggle (only when there are more than 7 days).
            if allDays.count > defaultDayCount {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAllReads.toggle()
                    }
                } label: {
                    Text(showAllReads ? "Show Less" : "Show All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }

            // Lifetime total + earliest date.
            VStack(spacing: 4) {
                Text("\(totalReadsAllTime) Logged \(totalReadsAllTime == 1 ? "Chapter" : "Chapters")")
                    .font(.title3.weight(.bold))
                    .foregroundColor(theme.textPrimary)

                if let earliest = earliestDate {
                    Text("Since \(earliest.formatted(date: .long, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
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

                        readingLogSection
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

// MARK: - LoggedReadCard

private struct LoggedReadCard: View {
    let bookName: String
    let chapter: Int
    let theme: Theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.subheadline)
                .foregroundColor(theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                Text("Chapter \(chapter)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.secondary.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.secondary.opacity(0.9), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HistoricalStatsView()
            .environmentObject(ThemeManager())
    }
}
