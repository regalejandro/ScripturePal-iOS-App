//
//  BookDetailView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/18/25.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    let book: Book

    // Logging flow state
    @State private var selectedChapter: Int?
    @State private var showingDatePicker = false
    @State private var pickedDate = Date()
    @State private var showingReadAlert = false
    @State private var logConfirmationMessage = ""

    private var theme: Theme { themeManager.current }

    /// "Group" / "Groups" depending on how many groups the book belongs to.
    private var groupLabel: String {
        book.groups.count > 1 ? "Groups" : "Group"
    }

    /// Full testament name, expanded from the stored abbreviation (e.g. "OT").
    private var testamentName: String {
        switch book.section.trimmingCharacters(in: .whitespaces).uppercased() {
        case "OT", "OLD", "OLD TESTAMENT":
            return "Old Testament"
        case "NT", "NEW", "NEW TESTAMENT":
            return "New Testament"
        default:
            return book.section
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                header

                chaptersSection

                historySection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
        // Step 2 (optional): pick a custom date.
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        // Step 3: confirmation, matching the app's existing alert.
        .alert(logConfirmationMessage, isPresented: $showingReadAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(book.name)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Subheading: which testament the book belongs to.
            Text(testamentName)
                .font(.title3.weight(.semibold))
                .foregroundColor(theme.primary)

            // Group membership.
            Text("\(groupLabel): \(book.groups.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            // Clear chapter count display.
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                Text("\(book.chapters) \(book.chapters == 1 ? "Chapter" : "Chapters")")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(theme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(theme.accent.opacity(0.10))
            )
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chapters

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chapters")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Text("Tap a chapter to log a reading.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            // ~7 squares per row on an iPhone; more on larger screens.
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 44), spacing: 8)],
                spacing: 8
            ) {
                ForEach(1...book.chapters, id: \.self) { chapter in
                    Button {
                        selectedChapter = chapter
                    } label: {
                        ChapterSquare(number: chapter, theme: theme)
                    }
                    .buttonStyle(PressableSquareStyle())
                    .popover(isPresented: optionsBinding(for: chapter)) {
                        logOptionsPopover(for: chapter)
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
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

    // MARK: - History grid

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All-Time Reading")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            BookHistoryGrid(book: book, theme: theme)
        }
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

    // MARK: - Date picker sheet

    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Reading Date",
                    selection: $pickedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(theme.primary)
                .padding()

                Spacer()
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(selectedChapter.map { "\(book.name) \($0)" } ?? "Pick a Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDatePicker = false
                        selectedChapter = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        if let chapter = selectedChapter {
                            logReading(chapter: chapter, date: pickedDate)
                        }
                        showingDatePicker = false
                        selectedChapter = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Log options popover

    /// The options popover for `chapter` is shown when it is the selected chapter
    /// and no date sheet is up. Anchors the popover to that specific square.
    private func optionsBinding(for chapter: Int) -> Binding<Bool> {
        Binding(
            get: { selectedChapter == chapter && !showingDatePicker },
            set: { isShown in
                if !isShown && selectedChapter == chapter {
                    selectedChapter = nil
                }
            }
        )
    }

    private func logOptionsPopover(for chapter: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Log \(book.name) \(chapter)")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()

            Button {
                logReading(chapter: chapter, date: .now)
                selectedChapter = nil
            } label: {
                Label("Log for Today", systemImage: "checkmark.circle")
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }

            Divider()

            Button {
                pickedDate = Date()
                showingDatePicker = true
            } label: {
                Label("Log for a Specific Date", systemImage: "calendar")
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .tint(theme.accent)
        .frame(width: 240)
        .background(theme.background)
    }

    // MARK: - Logging

    private func logReading(chapter: Int, date: Date) {
        let record = ReadingRecord(canonicalKey: book.canonicalKey, chapter: chapter, date: date)
        modelContext.insert(record)

        if Calendar.current.isDateInToday(date) {
            logConfirmationMessage =
                "Reading of \(book.name) \(chapter) has been logged for today's date."
        } else {
            let formatted = date.formatted(date: .long, time: .omitted)
            logConfirmationMessage =
                "Reading of \(book.name) \(chapter) has been logged for \(formatted)."
        }
        showingReadAlert = true
    }
}

// MARK: - ChapterSquare

private struct ChapterSquare: View {
    let number: Int
    let theme: Theme

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(theme.secondary.opacity(0.18))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.secondary.opacity(0.9), lineWidth: 1)
            )
            .overlay(
                Text("\(number)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(2)
            )
    }
}

// MARK: - PressableSquareStyle

/// Subtle press feedback so the chapter squares read as tappable.
private struct PressableSquareStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - BookHistoryGrid

/// All-time heatmap for a single book, reusing the StatsView grid style.
/// Isolated so its @Query reacts live to new readings for this book.
private struct BookHistoryGrid: View {

    let book: Book
    let theme: Theme

    @Query private var records: [ReadingRecord]
    @State private var availableWidth: CGFloat = 0

    private let squareSize: CGFloat = 12
    private let gap: CGFloat = 3

    init(book: Book, theme: Theme) {
        self.book = book
        self.theme = theme
        let key = book.canonicalKey
        _records = Query(filter: #Predicate<ReadingRecord> { $0.canonicalKey == key })
    }

    private var chapterCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for record in records {
            counts[record.chapter, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        let squaresPerRow = max(1, Int((availableWidth + gap) / (squareSize + gap)))
        BookGridRow(
            book: book,
            chapterCounts: chapterCounts,
            squaresPerRow: squaresPerRow,
            squareSize: squareSize,
            gap: gap,
            theme: theme
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newValue in
                        availableWidth = newValue
                    }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(book: Book(id: 1, name: "Genesis", chapters: 50, groups: ["Pentateuch"], section: "Old Testament", canonicalKey: "genesis"))
            .environmentObject(ThemeManager())
    }
}
