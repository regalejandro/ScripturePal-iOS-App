//
//  StatsView.swift
//  ScripturePal
//
//  Created by Alejandro Regalado on 6/5/26.
//

import SwiftUI
import SwiftData
import UIKit

struct StatsView: View {

    @Query private var records: [ReadingRecord]
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @StateObject private var bible = BibleManager()

    // Grid dimensions
    private let squareSize: CGFloat = 12
    private let gap: CGFloat = 3
    /// Caps content width on wide/landscape screens so there's margin at the edges.
    private let maxContentWidth: CGFloat = 640

    /// iPad shows the title inside the (margined) content so it lines up with it.
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

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

    // MARK: - Testament progress (this year)

    private func isOldTestament(_ section: String) -> Bool {
        ["OT", "OLD", "OLD TESTAMENT"]
            .contains(section.trimmingCharacters(in: .whitespaces).uppercased())
    }

    /// Unique chapters read this year out of total chapters, split by testament.
    private var testamentProgressThisYear: (old: (read: Int, total: Int), new: (read: Int, total: Int)) {
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
        for record in thisYearRecords {
            let id = "\(record.canonicalKey)-\(record.chapter)"
            if oldKeys.contains(record.canonicalKey) {
                oldRead.insert(id)
            } else if newKeys.contains(record.canonicalKey) {
                newRead.insert(id)
            }
        }

        return ((oldRead.count, oldTotal), (newRead.count, newTotal))
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

    /// Streak length plus the dates that bound it.
    private struct StreakInfo {
        var current: Int = 0
        var currentStart: Date?
        var best: Int = 0
        var bestStart: Date?
        var bestEnd: Date?
    }

    private var streakInfo: StreakInfo {
        let cal = Calendar.current
        let days = Set(records.map { cal.startOfDay(for: $0.date) }).sorted()
        guard !days.isEmpty else { return StreakInfo() }
        let daySet = Set(days)

        var info = StreakInfo()

        // ── Current streak ──────────────────────────────────────────────────
        // If today has reads, count from today. If not, count from yesterday —
        // the streak is still alive until a full day passes with no reads.
        let today = cal.startOfDay(for: .now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let startDay = daySet.contains(today) ? today
                     : (daySet.contains(yesterday) ? yesterday : nil)

        if let startDay {
            var checkDay = startDay
            while daySet.contains(checkDay) {
                info.current += 1
                info.currentStart = checkDay
                checkDay = cal.date(byAdding: .day, value: -1, to: checkDay)!
            }
        }

        // ── Best streak (with its date range) ───────────────────────────────
        var best = 1, run = 1
        var runStart = days[0]
        info.bestStart = days[0]
        info.bestEnd = days[0]
        for i in 1..<days.count {
            let gap = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 {
                run += 1
            } else {
                run = 1
                runStart = days[i]
            }
            if run > best {
                best = run
                info.bestStart = runStart
                info.bestEnd = days[i]
            }
        }
        info.best = best

        return info
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
        NavigationStack {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                GeometryReader { geo in
                    let contentWidth = min(geo.size.width, maxContentWidth)
                    let availableWidth = contentWidth - 32
                    let squaresPerRow = max(1, Int((availableWidth + gap) / (squareSize + gap)))

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {

                            if isPad {
                                Text("Reading Stats")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(themeManager.current.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

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
                            let streaks = streakInfo
                            StreakCard(
                                currentStreak: streaks.current,
                                currentStreakStart: streaks.currentStart,
                                bestStreak: streaks.best,
                                bestStreakStart: streaks.bestStart,
                                bestStreakEnd: streaks.bestEnd,
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
                                oldTestament: testamentProgressThisYear.old,
                                newTestament: testamentProgressThisYear.new,
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
                        .frame(maxWidth: maxContentWidth)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isPad ? "" : "Reading Stats")
            .navigationBarTitleDisplayMode(isPad ? .inline : .automatic)
        }
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .environmentObject(ThemeManager())
}
