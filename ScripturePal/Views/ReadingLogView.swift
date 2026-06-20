//
//  ReadingLogView.swift
//  ScripturePal
//
//  A reusable, date-grouped log of logged readings with edit/delete support.
//  Shared by HistoricalStatsView (all books) and BookDetailView (one book).
//

import SwiftUI
import SwiftData

/// One entry in the log: either a single chapter read, or a cover-to-cover
/// book completion (shown with a different symbol).
private enum LogEntry: Identifiable {
    case chapter(ReadingRecord)
    case completion(BookCompletion)

    var id: PersistentIdentifier {
        switch self {
        case .chapter(let record): return record.persistentModelID
        case .completion(let event): return event.persistentModelID
        }
    }

    var date: Date {
        switch self {
        case .chapter(let record): return record.date
        case .completion(let event): return event.completedAt
        }
    }
}

struct ReadingLogView: View {

    /// The chapter reads to display. The caller decides the scope (all books, one book…).
    let records: [ReadingRecord]
    /// The book completions to display alongside the chapter reads.
    var completions: [BookCompletion] = []
    /// Resolves a canonicalKey to its display book name.
    let bookName: (String) -> String
    let theme: Theme
    /// Number of most-recent logged dates shown before "Show All".
    var defaultDayCount: Int = 7

    @State private var showAll = false

    /// Logged entries grouped by calendar day, newest day first and newest
    /// entry first within each day.
    private var entriesByDay: [(day: Date, entries: [LogEntry])] {
        let cal = Calendar.current
        let entries: [LogEntry] = records.map(LogEntry.chapter) + completions.map(LogEntry.completion)
        let groups = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return groups
            .map { (day: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    private var earliestDate: Date? {
        records.map(\.date).min()
    }

    var body: some View {
        if entriesByDay.isEmpty {
            Text("No reading history yet.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        } else {
            let allDays = entriesByDay
            let visibleDays = showAll ? allDays : Array(allDays.prefix(defaultDayCount))

            VStack(alignment: .leading, spacing: 16) {

                ForEach(visibleDays, id: \.day) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.day.formatted(date: .long, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.textSecondary)

                        ForEach(group.entries) { entry in
                            switch entry {
                            case .chapter(let record):
                                LoggedReadCard(
                                    record: record,
                                    bookName: bookName(record.canonicalKey),
                                    theme: theme
                                )
                            case .completion(let event):
                                LoggedCompletionCard(
                                    completion: event,
                                    bookName: bookName(event.canonicalKey),
                                    theme: theme
                                )
                            }
                        }
                    }
                }

                // Show All / Show Less toggle (only when beyond the default count).
                if allDays.count > defaultDayCount {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAll.toggle()
                        }
                    } label: {
                        Text(showAll ? "Show Less" : "Show All")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }

                // Lifetime total + earliest date.
                VStack(spacing: 4) {
                    Text("\(records.count) Logged \(records.count == 1 ? "Chapter" : "Chapters")")
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
    }
}

// MARK: - LoggedReadCard

struct LoggedReadCard: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var completions: [BookCompletion]
    @Query private var sessions: [CurrentlyReading]

    let record: ReadingRecord
    let bookName: String
    let theme: Theme

    @State private var showingDatePicker = false
    @State private var pickedDate = Date()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.subheadline)
                .foregroundColor(theme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                Text("Chapter \(record.chapter)")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer(minLength: 0)

            // Edit / delete menu.
            Menu {
                Button {
                    pickedDate = record.date
                    showingDatePicker = true
                } label: {
                    Label("Edit Date", systemImage: "calendar")
                }

                Button(role: .destructive) {
                    deleteRecord()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundColor(theme.primary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
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
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }

    /// Deleting a logged read also revokes any book completion that depended
    /// on it — a "times read" can only stand if every chapter that earned it
    /// is still logged. If the revoked completion belongs to the book's
    /// active session, that session is no longer actually complete, so its
    /// "completed" flag (which gates the Read Again / Remove buttons and the
    /// one-time alert) is cleared too.
    private func deleteRecord() {
        for event in completions where event.contributingRecordIDs.contains(record.id) {
            modelContext.delete(event)
            if let session = sessions.first(where: { $0.canonicalKey == event.canonicalKey }) {
                session.completed = false
            }
        }
        modelContext.delete(record)
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
            .navigationTitle("\(bookName) \(record.chapter)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDatePicker = false }
                        .tint(theme.warning)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        record.date = pickedDate
                        showingDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - LoggedCompletionCard

/// A cover-to-cover book completion in the reading log, shown with a
/// different symbol than individual chapter reads.
struct LoggedCompletionCard: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [CurrentlyReading]

    let completion: BookCompletion
    let bookName: String
    let theme: Theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.subheadline)
                .foregroundColor(theme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                Text("Finished reading")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer(minLength: 0)

            Menu {
                Button(role: .destructive) {
                    deleteCompletion()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundColor(theme.primary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.primary.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.primary.opacity(0.5), lineWidth: 1)
        )
    }

    /// Revoking a completion directly means the active session (if this is
    /// it) is no longer actually complete, so its "completed" flag is
    /// cleared too — otherwise the Read Again / Remove buttons would stay
    /// stuck on and the session could never finish again.
    private func deleteCompletion() {
        if let session = sessions.first(where: { $0.canonicalKey == completion.canonicalKey }) {
            session.completed = false
        }
        modelContext.delete(completion)
    }
}
