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

    private var last40Days: (counts: [Int], totalReads: Int, activeDays: Int, bestDay: Int) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        var dayCount: [Date: Int] = [:]
        for record in records {
            dayCount[cal.startOfDay(for: record.date), default: 0] += 1
        }

        let counts: [Int] = (0..<40).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            return dayCount[day] ?? 0
        }

        return (counts, counts.reduce(0, +), counts.filter { $0 > 0 }.count, counts.max() ?? 0)
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        var dayCount: [Date: Int] = [:]
        for record in records {
            dayCount[cal.startOfDay(for: record.date), default: 0] += 1
        }
        var streak = 0
        var checkDay = cal.startOfDay(for: .now)
        while dayCount[checkDay, default: 0] > 0 {
            streak += 1
            checkDay = cal.date(byAdding: .day, value: -1, to: checkDay)!
        }
        return streak
    }

    private var bestStreak: Int {
        let cal = Calendar.current
        let sortedDays = Set(records.map { cal.startOfDay(for: $0.date) }).sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var best = 1, current = 1
        for i in 1..<sortedDays.count {
            let gap = cal.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day ?? 0
            current = gap == 1 ? current + 1 : 1
            best = max(best, current)
        }
        return best
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
                                theme: themeManager.current
                            )

                            // ── Streak card ───────────────────────────────────
                            StreakCard(
                                currentStreak: currentStreak,
                                bestStreak: bestStreak,
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
