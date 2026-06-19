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
    @Query(sort: \CustomGroup.createdAt) private var customGroups: [CustomGroup]
    @Query private var currentlyReading: [CurrentlyReading]
    @Query private var completions: [BookCompletion]
    @Query private var records: [ReadingRecord]

    let book: Book

    // Logging flow state
    @State private var selectedChapter: Int?
    @State private var showingDatePicker = false
    @State private var pickedDate = Date()
    @State private var showingReadAlert = false
    @State private var logConfirmationMessage = ""

    // Group management state
    @State private var showingNewGroup = false
    @State private var newGroupName = ""
    @State private var showingGroupManager = false

    // Reading session state
    @State private var showingCompletionAlert = false
    @State private var showingAddToReadingAlert = false
    @State private var pendingAddToReadingRecord: ReadingRecord?

    init(book: Book) {
        self.book = book
        let key = book.canonicalKey
        _records = Query(filter: #Predicate<ReadingRecord> { $0.canonicalKey == key })
    }

    private var theme: Theme { themeManager.current }

    /// All groups this book belongs to: its built-in default groups plus any
    /// custom groups that currently contain it.
    private var membershipGroups: [String] {
        let custom = customGroups
            .filter { $0.contains(book.canonicalKey) }
            .map { $0.name }
        return book.groups + custom
    }

    /// "Group" / "Groups" depending on how many groups the book belongs to.
    private var groupLabel: String {
        membershipGroups.count > 1 ? "Groups" : "Group"
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

                readingLogSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
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
        // Cover-to-cover completion of the current reading session.
        .alert("You've finished \(book.name)!", isPresented: $showingCompletionAlert) {
            Button("Read Again") { startNewSession() }
            Button("Done Reading", role: .destructive) { removeFromCurrentlyReading() }
            Button("Stay in Session", role: .cancel) { }
        } message: {
            Text("You've read every chapter this session. What next?")
        }
        // Offer to start a session when logging a chapter of a book that
        // isn't currently being read.
        .alert("Add \(book.name) to Currently Reading?", isPresented: $showingAddToReadingAlert) {
            Button("Add to Currently Reading") { confirmAddToReading() }
            Button("Not Now", role: .cancel) { pendingAddToReadingRecord = nil }
        } message: {
            Text("This chapter has been logged. A full reading of \(book.name) will only count if you start a reading session.")
        }
        // New custom group (adds this book to it).
        .alert("New Group", isPresented: $showingNewGroup) {
            TextField("Group name", text: $newGroupName)
            Button("Create") { createGroupAndAdd() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\(book.name) will be added to the new group.")
        }
        .sheet(isPresented: $showingGroupManager) {
            NavigationStack {
                GroupManagerView(onClose: { showingGroupManager = false })
            }
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

            // Group membership (default + custom groups).
            Text("\(groupLabel): \(membershipGroups.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            // Custom group actions.
            Menu {
                if !customGroups.isEmpty {
                    Section("Add to Group") {
                        ForEach(customGroups) { group in
                            Button {
                                toggleMembership(group)
                            } label: {
                                if group.contains(book.canonicalKey) {
                                    Label(group.name, systemImage: "checkmark")
                                } else {
                                    Text(group.name)
                                }
                            }
                        }
                    }
                }
                Button {
                    newGroupName = ""
                    showingNewGroup = true
                } label: {
                    Label("New Group…", systemImage: "plus")
                }
                Button {
                    showingGroupManager = true
                } label: {
                    Label("Manage Groups", systemImage: "rectangle.3.group")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                    Text("Add to Group")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.primary)
                .padding(.vertical, 2)
            }

            // Times read (lifetime completions).
            if timesRead > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Read \(timesRead) time\(timesRead == 1 ? "" : "s")")
                }
                .font(.caption.weight(.medium))
                .foregroundColor(theme.primary)
            }

            // Chapter count + currently-reading toggle.
            HStack(spacing: 10) {
                // Clear chapter count display.
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption)
                    Text("\(book.chapters) \(book.chapters == 1 ? "Chapter" : "Chapters")")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(theme.primary.opacity(0.10))
                )

                Spacer()

                // When the session is complete: Read Again / Remove.
                if isCurrentlyReading && sessionCompleted {
                    Button {
                        startNewSession()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Read Again")

                    Button {
                        removeFromCurrentlyReading()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.warning)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Done Reading")
                }

                // Currently-reading toggle.
                Button {
                    toggleCurrentlyReading()
                } label: {
                    HStack(spacing: 6) {
                        Text("Reading")
                        Image(systemName: isCurrentlyReading ? "checkmark.circle.fill" : "circle")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isCurrentlyReading ? theme.accent : theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill((isCurrentlyReading ? theme.accent : theme.secondary).opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: isCurrentlyReading)
            }
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

            Text(isCurrentlyReading
                 ? "Tap a chapter to log a reading. Chapters read this session are marked."
                 : "Tap a chapter to log a reading.")
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
                        ChapterSquare(
                            number: chapter,
                            isSessionRead: isCurrentlyReading && sessionChapters.contains(chapter),
                            theme: theme
                        )
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

    // MARK: - Reading log

    private var readingLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Log")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            BookReadingLog(book: book, theme: theme)
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
                    .tint(theme.warning)
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
        .tint(theme.primary)
        .frame(width: 240)
        .background(theme.background)
    }

    // MARK: - Currently reading

    private var readingSession: CurrentlyReading? {
        currentlyReading.first { $0.canonicalKey == book.canonicalKey }
    }

    private var isCurrentlyReading: Bool {
        readingSession != nil
    }

    /// Chapters covered this session: any chapter with a logged read dated at
    /// or after the session started. Derived live from `records`, so editing
    /// or deleting a read automatically updates this (and the checkmarks).
    private var sessionChapters: Set<Int> {
        guard let session = readingSession else { return [] }
        return Set(records.filter { $0.date >= session.addedAt }.map { $0.chapter })
    }

    /// Whether the current session has been completed and acknowledged.
    private var sessionCompleted: Bool {
        readingSession?.completed ?? false
    }

    /// How many times this book has been read cover-to-cover.
    private var timesRead: Int {
        completions.filter { $0.canonicalKey == book.canonicalKey }.count
    }

    private func toggleCurrentlyReading() {
        if let existing = readingSession {
            modelContext.delete(existing)
        } else {
            modelContext.insert(CurrentlyReading(canonicalKey: book.canonicalKey))
        }
    }

    /// Begin a fresh session for an already-current book (Read Again). Resets
    /// the session start so earlier reads no longer count toward it.
    private func startNewSession() {
        guard let session = readingSession else { return }
        session.addedAt = .now
        session.completed = false
    }

    private func removeFromCurrentlyReading() {
        if let session = readingSession {
            modelContext.delete(session)
        }
    }

    /// Starts a session for a book that wasn't being read, anchored to the
    /// chapter that was just logged so that read counts toward it. Only
    /// offered for multi-chapter books, so a single chapter can never
    /// complete the book on its own.
    private func confirmAddToReading() {
        guard let record = pendingAddToReadingRecord else { return }
        let session = CurrentlyReading(canonicalKey: book.canonicalKey)
        session.addedAt = record.date
        modelContext.insert(session)
        pendingAddToReadingRecord = nil
    }

    /// True once every chapter 1...book.chapters has a record dated at/after
    /// `session.addedAt`, treating `justLogged` as already present even
    /// though the @Query feeding `records` may not have caught up to it yet.
    private func sessionCoversAllChapters(session: CurrentlyReading, includingJustLogged justLogged: ReadingRecord) -> Bool {
        var chapters = Set(records.filter { $0.date >= session.addedAt }.map { $0.chapter })
        chapters.insert(justLogged.chapter)
        return chapters.isSuperset(of: 1...book.chapters)
    }

    /// For each chapter 1...book.chapters, the id of the earliest record (at
    /// or after the session start) that satisfied it — the reads this
    /// completion depends on. If any of them is later deleted, the
    /// completion they produced should be revoked.
    private func contributingRecordIDs(session: CurrentlyReading, justLogged: ReadingRecord) -> [UUID] {
        var earliestByChapter: [Int: ReadingRecord] = [:]
        for record in records + [justLogged] where record.date >= session.addedAt {
            if let existing = earliestByChapter[record.chapter] {
                if record.date < existing.date { earliestByChapter[record.chapter] = record }
            } else {
                earliestByChapter[record.chapter] = record
            }
        }
        return (1...book.chapters).compactMap { earliestByChapter[$0]?.id }
    }

    /// Records a chapter read this session. Returns true if this read just
    /// completed the book cover-to-cover (so the caller can show the
    /// completion prompt instead of the normal confirmation).
    @discardableResult
    private func recordSessionRead(_ record: ReadingRecord) -> Bool {
        guard let session = readingSession, !session.completed else { return false }
        guard sessionCoversAllChapters(session: session, includingJustLogged: record) else { return false }

        session.completed = true
        let ids = contributingRecordIDs(session: session, justLogged: record)
        modelContext.insert(BookCompletion(canonicalKey: book.canonicalKey, contributingRecordIDs: ids))
        return true
    }

    // MARK: - Custom groups

    private func toggleMembership(_ group: CustomGroup) {
        if group.contains(book.canonicalKey) {
            group.remove(book.canonicalKey)
        } else {
            group.add(book.canonicalKey)
        }
    }

    private func createGroupAndAdd() {
        let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(CustomGroup(name: trimmed, bookKeys: [book.canonicalKey]))
        newGroupName = ""
    }

    // MARK: - Logging

    private func logReading(chapter: Int, date: Date) {
        let record = ReadingRecord(canonicalKey: book.canonicalKey, chapter: chapter, date: date)
        modelContext.insert(record)

        if isCurrentlyReading {
            // Track session progress. If this read finished the book, show the
            // completion prompt instead of the usual confirmation.
            if recordSessionRead(record) {
                showingCompletionAlert = true
                return
            }
        } else if book.chapters == 1 {
            // A single-chapter book is finished outright by this one read, so
            // there's no session to start — just record the completion.
            modelContext.insert(BookCompletion(canonicalKey: book.canonicalKey, contributingRecordIDs: [record.id]))
        } else {
            // Not currently reading a multi-chapter book: offer to start a
            // session so future reads count toward it.
            pendingAddToReadingRecord = record
            showingAddToReadingAlert = true
            return
        }

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
    var isSessionRead: Bool = false
    let theme: Theme

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSessionRead ? theme.primary.opacity(0.22) : theme.secondary.opacity(0.18))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSessionRead ? theme.primary : theme.secondary.opacity(0.9),
                            lineWidth: isSessionRead ? 1.5 : 1)
            )
            .overlay(
                Text("\(number)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isSessionRead ? theme.primary : theme.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(2)
            )
            // Session-read check badge in the corner.
            .overlay(alignment: .topTrailing) {
                if isSessionRead {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.primary)
                        .background(Circle().fill(theme.background))
                        .padding(2)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isSessionRead)
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

    private func color(for count: Int) -> Color {
        switch count {
        case 0:   return theme.secondary.opacity(0.25)
        case 1:   return theme.accent.opacity(0.25)
        case 2:   return theme.accent.opacity(0.45)
        case 3:   return theme.accent.opacity(0.65)
        case 4:   return theme.accent.opacity(0.82)
        default:  return theme.accent.opacity(1.0)
        }
    }

    var body: some View {
        // Adaptive grid reflows to the available width automatically, so it
        // can't get stuck at a stale (landscape) width on rotation.
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: squareSize, maximum: squareSize), spacing: gap)],
            alignment: .leading,
            spacing: gap
        ) {
            ForEach(1...max(1, book.chapters), id: \.self) { chapter in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: chapterCounts[chapter] ?? 0))
                    .frame(width: squareSize, height: squareSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - BookReadingLog

/// The shared reading log scoped to a single book. Isolated so its @Query
/// reacts live to readings logged, edited, or deleted for this book.
private struct BookReadingLog: View {

    let book: Book
    let theme: Theme

    @Query private var records: [ReadingRecord]
    @Query private var completions: [BookCompletion]

    init(book: Book, theme: Theme) {
        self.book = book
        self.theme = theme
        let key = book.canonicalKey
        _records = Query(filter: #Predicate<ReadingRecord> { $0.canonicalKey == key })
        _completions = Query(filter: #Predicate<BookCompletion> { $0.canonicalKey == key })
    }

    var body: some View {
        ReadingLogView(
            records: records,
            completions: completions,
            bookName: { _ in book.name },
            theme: theme
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
