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

    private var totalReadsThisYear: Int { thisYearRecords.count }

    private var uniqueChaptersThisYear: Int {
        Set(thisYearRecords.map { "\($0.canonicalKey)-\($0.chapter)" }).count
    }

    private var totalChaptersInTranslation: Int {
        bible.books(for: selectedTranslation).reduce(0) { $0 + $1.chapters }
    }

    private var progressFraction: Double {
        guard totalChaptersInTranslation > 0 else { return 0 }
        return Double(uniqueChaptersThisYear) / Double(totalChaptersInTranslation)
    }

    private var readsByMonth: [Int: Int] {
        var counts: [Int: Int] = [:]
        for record in thisYearRecords {
            let month = Calendar.current.component(.month, from: record.date)
            counts[month, default: 0] += 1
        }
        return counts
    }

    private var bestMonth: (name: String, count: Int)? {
        guard let top = readsByMonth.max(by: { $0.value < $1.value }), top.value > 0 else { return nil }
        return (Calendar.current.monthSymbols[top.key - 1], top.value)
    }

    // MARK: - Last 40 days

    private var last40Days: (counts: [Int], totalReads: Int, activeDays: Int, bestDay: Int, currentStreak: Int) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // Map each record's date to its start-of-day bucket
        var dayCount: [Date: Int] = [:]
        for record in records {
            let day = cal.startOfDay(for: record.date)
            dayCount[day, default: 0] += 1
        }

        // Build ordered array: index 0 = 39 days ago, index 39 = today
        let counts: [Int] = (0..<40).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            return dayCount[day] ?? 0
        }

        let totalReads  = counts.reduce(0, +)
        let activeDays  = counts.filter { $0 > 0 }.count
        let bestDay     = counts.max() ?? 0

        // Streak: walk backwards from today through ALL records, not just 40 days
        var streak = 0
        var checkDay = today
        while true {
            if dayCount[checkDay, default: 0] > 0 {
                streak += 1
                checkDay = cal.date(byAdding: .day, value: -1, to: checkDay)!
            } else {
                break
            }
        }

        return (counts, totalReads, activeDays, bestDay, streak)
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

                            // ── Recent activity card ─────────────────────────
                            let d = last40Days
                            RecentActivityCard(
                                dailyCounts: d.counts,
                                totalReads: d.totalReads,
                                activeDays: d.activeDays,
                                bestDay: d.bestDay,
                                currentStreak: d.currentStreak,
                                theme: themeManager.current
                            )

                            // ── This year's card ─────────────────────────────
                            YearStatsCard(
                                year: currentYear,
                                totalReads: totalReadsThisYear,
                                uniqueChapters: uniqueChaptersThisYear,
                                totalChapters: totalChaptersInTranslation,
                                progressFraction: progressFraction,
                                bestMonth: bestMonth,
                                readsByMonth: readsByMonth,
                                theme: themeManager.current
                            )

                            // ── History button ───────────────────────────────
                            NavigationLink {
                                HistoricalStatsView()
                                    .environmentObject(themeManager)
                            } label: {
                                HStack {
                                    Text("View Reading History")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundColor(themeManager.current.textSecondary)
                                .padding(.horizontal, 4)
                            }

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
                                    theme: themeManager.current
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

// MARK: - Preview

#Preview {
    StatsView()
        .environmentObject(ThemeManager())
}
