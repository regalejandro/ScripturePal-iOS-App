//
//  StatsComponents.swift
//  ScripturePal
//
//  Shared stat subviews used by both StatsView and HistoricalStatsView.
//

import SwiftUI
import UIKit

// MARK: - YearStatsCard

struct YearStatsCard: View {

    let year: Int
    let totalReads: Int
    let uniqueChapters: Int
    let totalChapters: Int
    let booksCompleted: Int
    let progressFraction: Double
    let bestMonth: (name: String, count: Int)?
    let readsByMonth: [Int: Int]
    let oldTestament: (read: Int, total: Int)
    let newTestament: (read: Int, total: Int)
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("\(String(year)) Reading")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            // ── Key numbers ──────────────────────────────────────────────────
            HStack(spacing: 0) {
                StatPill(value: "\(totalReads)",
                         label: "Reads Logged",
                         theme: theme)
                Divider().frame(height: 36)
                StatPill(value: "\(uniqueChapters) / \(totalChapters)",
                         label: "Chapters",
                         theme: theme)
                Divider().frame(height: 36)
                StatPill(value: "\(booksCompleted)",
                         label: "Books Read",
                         theme: theme)
                Divider().frame(height: 36)
                StatPill(value: String(format: "%.1f%%", progressFraction * 100),
                         label: "Coverage",
                         theme: theme)
            }
            .frame(maxWidth: .infinity)

            // ── Progress bar ─────────────────────────────────────────────────
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.secondary.opacity(0.3))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accent)
                        .frame(width: geo.size.width * progressFraction, height: 8)
                        .animation(.easeOut(duration: 0.6), value: progressFraction)
                }
            }
            .frame(height: 8)

            // ── Best month ───────────────────────────────────────────────────
            if let best = bestMonth {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(theme.primary)
                    Text("Best month: \(best.name) · \(best.count) chapter\(best.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }

            Divider()

            // ── Monthly bar chart ────────────────────────────────────────────
            MonthlyBarChart(readsByMonth: readsByMonth, theme: theme)

            Divider()

            // ── Testament progress ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                TestamentProgressRow(
                    label: "Old Testament",
                    read: oldTestament.read,
                    total: oldTestament.total,
                    theme: theme
                )
                TestamentProgressRow(
                    label: "New Testament",
                    read: newTestament.read,
                    total: newTestament.total,
                    theme: theme
                )
            }
        }
        .statsCardStyle(theme: theme)
    }
}

// MARK: - AllTimeStatsCard

struct AllTimeStatsCard: View {

    let totalReads: Int
    let uniqueChapters: Int
    let totalChapters: Int
    let booksCompleted: Int
    let progressFraction: Double
    let bestYear: (year: Int, count: Int)?
    let mostReadBook: (name: String, count: Int)?
    let mostRecentCompletion: (name: String, date: Date)?
    let yearsActive: Int
    let readsByYear: [Int: Int]
    let oldTestament: (read: Int, total: Int)
    let newTestament: (read: Int, total: Int)
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("All-Time Reading")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            // ── Key numbers ──────────────────────────────────────────────────
            HStack(spacing: 0) {
                StatPill(value: "\(totalReads)",
                         label: "Reads Logged",
                         theme: theme)
                Divider().frame(height: 36)
                StatPill(value: "\(uniqueChapters) / \(totalChapters)",
                         label: "Chapters",
                         theme: theme)
                Divider().frame(height: 36)
                StatPill(value: "\(booksCompleted)",
                         label: "Books Read",
                         theme: theme)
                Divider().frame(height: 36)
                StatPill(value: String(format: "%.1f%%", progressFraction * 100),
                         label: "Coverage",
                         theme: theme)
            }
            .frame(maxWidth: .infinity)

            // ── Progress bar ─────────────────────────────────────────────────
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.secondary.opacity(0.3))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accent)
                        .frame(width: geo.size.width * progressFraction, height: 8)
                        .animation(.easeOut(duration: 0.6), value: progressFraction)
                }
            }
            .frame(height: 8)

            // ── Highlights ───────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                if let best = bestYear {
                    HighlightRow(
                        icon: "trophy.fill",
                        text: "Best year: \(String(best.year)) · \(best.count) chapter\(best.count == 1 ? "" : "s") read",
                        theme: theme
                    )
                }
                if let book = mostReadBook {
                    HighlightRow(
                        icon: "book.fill",
                        text: "Most read: \(book.name) · \(book.count) chapter\(book.count == 1 ? "" : "s") read",
                        theme: theme
                    )
                }
                if let recent = mostRecentCompletion {
                    HighlightRow(
                        icon: "checkmark.seal.fill",
                        text: "Most recent book: \(recent.name) · \(recent.date.formatted(date: .abbreviated, time: .omitted))",
                        theme: theme
                    )
                }
                HighlightRow(
                    icon: "calendar",
                    text: "Active across \(yearsActive) calendar year\(yearsActive == 1 ? "" : "s")",
                    theme: theme
                )
            }

            if readsByYear.count > 1 {
                Divider()

                // ── Year-over-year chart ─────────────────────────────────────
                YearlyBarChart(readsByYear: readsByYear, theme: theme)
            }

            Divider()

            // ── Testament progress ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                TestamentProgressRow(
                    label: "Old Testament",
                    read: oldTestament.read,
                    total: oldTestament.total,
                    theme: theme
                )
                TestamentProgressRow(
                    label: "New Testament",
                    read: newTestament.read,
                    total: newTestament.total,
                    theme: theme
                )
            }
        }
        .statsCardStyle(theme: theme)
    }
}

// MARK: - TestamentProgressRow

/// A labeled progress bar with "read / total · pct%" for one testament.
private struct TestamentProgressRow: View {
    let label: String
    let read: Int
    let total: Int
    let theme: Theme

    private var fraction: Double { total > 0 ? Double(read) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(read) / \(total) · \(String(format: "%.0f", fraction * 100))%")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.secondary.opacity(0.3))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accent)
                        .frame(width: geo.size.width * fraction, height: 8)
                        .animation(.easeOut(duration: 0.6), value: fraction)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - StatPill

struct StatPill: View {
    let value: String
    let label: String
    let theme: Theme

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HighlightRow

struct HighlightRow: View {
    let icon: String
    let text: String
    let theme: Theme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(theme.primary)
            Text(text)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - MonthlyBarChart

struct MonthlyBarChart: View {

    let readsByMonth: [Int: Int]
    let theme: Theme

    private let monthAbbrevs = ["J","F","M","A","M","J","J","A","S","O","N","D"]
    private let monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]
    private let maxBarHeight: CGFloat = 40

    private var maxCount: Int { readsByMonth.values.max() ?? 1 }

    /// Index (0...11) of the bar the user is currently pressing, if any.
    @State private var activeIndex: Int?

    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / 12

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(1...12, id: \.self) { month in
                    let count = readsByMonth[month] ?? 0
                    let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                    let isActive = activeIndex == month - 1
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(count > 0
                                  ? theme.accent.opacity(0.3 + 0.7 * fraction)
                                  : theme.secondary.opacity(0.25))
                            .frame(height: max(4, maxBarHeight * fraction))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(theme.accent, lineWidth: isActive ? 2 : 0)
                            )
                            .animation(.easeOut(duration: 0.4), value: count)
                        Text(monthAbbrevs[month - 1])
                            .font(.system(size: 8))
                            .foregroundColor(isActive ? theme.accent : theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxBarHeight + 16, alignment: .bottom)
            // Tooltip floating above the active bar.
            .overlay(alignment: .topLeading) {
                if let idx = activeIndex {
                    BarTooltip(title: monthNames[idx],
                               count: readsByMonth[idx + 1] ?? 0,
                               theme: theme)
                        .alignmentGuide(.top) { d in d[.bottom] + 6 }
                        .alignmentGuide(.leading) { d in d.width / 2 - (CGFloat(idx) + 0.5) * cellWidth }
                        .animation(.easeOut(duration: 0.12), value: activeIndex)
                }
            }
            .contentShape(Rectangle())
            .barInspect(count: 12) { activeIndex = $0 }
        }
        .frame(height: maxBarHeight + 16)
    }
}

// MARK: - YearlyBarChart

struct YearlyBarChart: View {

    let readsByYear: [Int: Int]
    let theme: Theme

    private let maxBarHeight: CGFloat = 40

    private var sortedYears: [Int] { readsByYear.keys.sorted() }
    private var maxCount: Int { readsByYear.values.max() ?? 1 }

    /// Index into `sortedYears` of the bar the user is currently pressing, if any.
    @State private var activeIndex: Int?

    var body: some View {
        let years = sortedYears
        GeometryReader { geo in
            let cellWidth = years.isEmpty ? geo.size.width : geo.size.width / CGFloat(years.count)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(years.enumerated()), id: \.element) { index, year in
                    let count = readsByYear[year] ?? 0
                    let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                    let isActive = activeIndex == index
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.accent.opacity(0.3 + 0.7 * fraction))
                            .frame(height: max(4, maxBarHeight * fraction))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(theme.accent, lineWidth: isActive ? 2 : 0)
                            )
                            .animation(.easeOut(duration: 0.4), value: count)
                        Text(String(year).suffix(2).description) // e.g. "26"
                            .font(.system(size: 8))
                            .foregroundColor(isActive ? theme.accent : theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxBarHeight + 16, alignment: .bottom)
            .overlay(alignment: .topLeading) {
                if let idx = activeIndex, idx < years.count {
                    BarTooltip(title: String(years[idx]),
                               count: readsByYear[years[idx]] ?? 0,
                               theme: theme)
                        .alignmentGuide(.top) { d in d[.bottom] + 6 }
                        .alignmentGuide(.leading) { d in d.width / 2 - (CGFloat(idx) + 0.5) * cellWidth }
                        .animation(.easeOut(duration: 0.12), value: activeIndex)
                }
            }
            .contentShape(Rectangle())
            .barInspect(count: years.count) { activeIndex = $0 }
        }
        .frame(height: maxBarHeight + 16)
    }
}

// MARK: - Bar inspect gesture

/// A UIKit-backed press-and-hold scrub overlay that does **not** block the
/// surrounding ScrollView. It uses a `UILongPressGestureRecognizer` configured
/// to recognize *simultaneously* with the scroll view's pan: a normal swipe
/// (even starting on the chart) scrolls, and a brief deliberate hold reveals the
/// bar data, after which sliding left/right moves between bars. Reports the
/// active bar index, or `nil` when released.
private struct BarInspectOverlay: UIViewRepresentable {
    let count: Int
    var minimumPressDuration: TimeInterval = 0.2
    let onChange: (Int?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let press = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        press.minimumPressDuration = minimumPressDuration
        press.delegate = context.coordinator
        view.addGestureRecognizer(press)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: BarInspectOverlay
        /// The scroll view whose scrolling we paused during an active hold.
        private weak var pausedScrollView: UIScrollView?
        /// The navigation back-swipe we paused during an active hold.
        private weak var pausedPopGesture: UIGestureRecognizer?

        init(_ parent: BarInspectOverlay) { self.parent = parent }

        @objc func handle(_ gr: UILongPressGestureRecognizer) {
            guard let view = gr.view else { return }
            switch gr.state {
            case .began:
                // Hold recognized → freeze vertical scrolling and the navigation
                // back-swipe so the user can slide left/right between bars without
                // the screen moving or popping the page.
                let scrollView = enclosingScrollView(of: view)
                scrollView?.isScrollEnabled = false
                pausedScrollView = scrollView

                let popGesture = enclosingViewController(of: view)?
                    .navigationController?.interactivePopGestureRecognizer
                popGesture?.isEnabled = false
                pausedPopGesture = popGesture

                emit(gr, in: view)
            case .changed:
                // Re-assert in case SwiftUI re-enabled them between updates.
                pausedScrollView?.isScrollEnabled = false
                pausedPopGesture?.isEnabled = false
                emit(gr, in: view)
            case .ended, .cancelled, .failed:
                pausedScrollView?.isScrollEnabled = true
                pausedScrollView = nil
                pausedPopGesture?.isEnabled = true
                pausedPopGesture = nil
                parent.onChange(nil)
            default:
                break
            }
        }

        private func emit(_ gr: UILongPressGestureRecognizer, in view: UIView) {
            let width = view.bounds.width
            guard width > 0, parent.count > 0 else { return }
            let x = gr.location(in: view).x
            let cell = width / CGFloat(parent.count)
            let i = min(parent.count - 1, max(0, Int(x / cell)))
            parent.onChange(i)
        }

        private func enclosingScrollView(of view: UIView) -> UIScrollView? {
            var current = view.superview
            while let v = current {
                if let scroll = v as? UIScrollView { return scroll }
                current = v.superview
            }
            return nil
        }

        private func enclosingViewController(of view: UIView) -> UIViewController? {
            var responder: UIResponder? = view
            while let r = responder {
                if let vc = r as? UIViewController { return vc }
                responder = r.next
            }
            return nil
        }

        // Run alongside the scroll view's pan (so a normal swipe still scrolls
        // until a hold is recognized), but never alongside the navigation
        // back-swipe — while inspecting, that edge pan must not fire.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            if other is UIScreenEdgePanGestureRecognizer { return false }
            return true
        }
    }
}

private extension View {
    func barInspect(count: Int, onChange: @escaping (Int?) -> Void) -> some View {
        overlay(BarInspectOverlay(count: count, onChange: onChange))
    }
}

// MARK: - BarTooltip

/// Cute little callout bubble shown above a bar while the user presses it.
private struct BarTooltip: View {
    let title: String
    let count: Int
    let theme: Theme

    var body: some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundColor(theme.textPrimary)
            Text("\(title) · Read\(count == 1 ? "" : "s")")
                .font(.system(size: 8))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.secondary.opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.accent.opacity(0.5), lineWidth: 1)
        )
        .fixedSize()
        .allowsHitTesting(false)
    }
}

// MARK: - BookGridRow

struct BookGridRow: View {

    let book: Book
    let chapterCounts: [Int: Int]
    let squaresPerRow: Int
    let squareSize: CGFloat
    let gap: CGFloat
    let theme: Theme

    private var rows: [[Int]] {
        let chapters = Array(1...max(1, book.chapters))
        return stride(from: 0, to: chapters.count, by: squaresPerRow).map {
            Array(chapters[$0 ..< min($0 + squaresPerRow, chapters.count)])
        }
    }

    private func squareColor(for chapter: Int) -> Color {
        switch chapterCounts[chapter] ?? 0 {
        case 0:   return theme.secondary.opacity(0.25)
        case 1:   return theme.accent.opacity(0.35)
        case 2:   return theme.accent.opacity(0.50)
        case 3:   return theme.accent.opacity(0.70)
        case 4:   return theme.accent.opacity(0.85)
        default:  return theme.accent.opacity(1.0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.name)
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.textSecondary)

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

// MARK: - StreakCard

struct StreakCard: View {

    let currentStreak: Int
    let currentStreakStart: Date?
    let bestStreak: Int
    let bestStreakStart: Date?
    let bestStreakEnd: Date?
    let theme: Theme

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Current streak ───────────────────────────────────────────────
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(currentStreak > 0 ? theme.primary : theme.secondary.opacity(0.5))
                    Text("\(currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(currentStreak > 0 ? theme.textPrimary : theme.secondary.opacity(0.5))
                }
                Text("Current Streak")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.textSecondary)
                Text(currentStreak == 1 ? "day" : "days")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                if currentStreak > 0, let start = currentStreakStart {
                    Text("Since \(formatted(start))")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 70)

            // ── Best streak ──────────────────────────────────────────────────
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(theme.primary)
                    Text("\(bestStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }
                Text("Best Streak")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.textSecondary)
                Text(bestStreak == 1 ? "day" : "days")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary.opacity(0.7))

                if bestStreak > 0, let start = bestStreakStart, let end = bestStreakEnd {
                    Text(start == end
                         ? formatted(start)
                         : "\(formatted(start)) – \(formatted(end))")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .statsCardStyle(theme: theme)
    }
}

// MARK: - RecentActivityCard

struct RecentActivityCard: View {

    /// 40 read counts, index 0 = oldest day, index 39 = today
    let dailyCounts: [Int]
    let totalReads: Int
    let activeDays: Int
    let bestDay: Int
    let theme: Theme

    private let columns = 8
    private let squareSize: CGFloat = 13
    private let gap: CGFloat = 2

    private var maxCount: Int { dailyCounts.max() ?? 1 }

    private func color(for count: Int) -> Color {
        guard count > 0, maxCount > 0 else { return theme.secondary.opacity(0.2) }
        let intensity = 0.25 + 0.75 * (CGFloat(count) / CGFloat(maxCount))
        return theme.accent.opacity(intensity)
    }

    /// dailyCounts split into rows of `columns`
    private var rows: [[Int]] {
        stride(from: 0, to: dailyCounts.count, by: columns).map {
            Array(dailyCounts[$0 ..< min($0 + columns, dailyCounts.count)])
        }
    }

    var body: some View {
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Last 40 Days")
                .font(.headline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            
            HStack(alignment: .top, spacing: 14) {
                
                // ── Left: day grid ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: gap) {
                            ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                                let count = rows[rowIndex][colIndex]
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color(for: count))
                                    .frame(width: squareSize, height: squareSize)
                            }
                        }
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // ── Right: stats ─────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    
                    ActivityStatRow(
                        icon: "book.closed.fill",
                        label: "Total Reads",
                        value: "\(totalReads)",
                        theme: theme
                    )
                   
                    ActivityStatRow(
                        icon: "calendar.badge.checkmark",
                        label: "Active Days",
                        value: "\(activeDays) / 40",
                        theme: theme
                    )
             
                    ActivityStatRow(
                        icon: "star.fill",
                        label: "Best Day",
                        value: bestDay == 0 ? "—" : "\(bestDay)",
                        theme: theme
                    )
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
        .statsCardStyle(theme: theme)

    }
}

// MARK: - ActivityStatRow

private struct ActivityStatRow: View {
    let icon: String
    let label: String
    let value: String
    let theme: Theme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(theme.primary)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
            }
        }
    }
}

// MARK: - Card style helper

extension View {
    func statsCardStyle(theme: Theme) -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.secondary.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(theme.secondary.opacity(0.9), lineWidth: 1)
            )
    }
}
