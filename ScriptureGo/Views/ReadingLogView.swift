//
//  ReadingLogView.swift
//  ScriptureGo
//
//  A reusable, date-grouped log of logged readings with edit/delete support.
//  Shared by HistoricalStatsView (all books) and BookDetailView (one book).
//

import SwiftUI
import SwiftData

struct ReadingLogView: View {

    /// The reads to display. The caller decides the scope (all books, one book…).
    let records: [ReadingRecord]
    /// Resolves a canonicalKey to its display book name.
    let bookName: (String) -> String
    let theme: Theme
    /// Number of most-recent logged dates shown before "Show All".
    var defaultDayCount: Int = 7

    @State private var showAll = false

    /// Logged reads grouped by calendar day, newest day first and newest read
    /// first within each day.
    private var recordsByDay: [(day: Date, records: [ReadingRecord])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: records) { cal.startOfDay(for: $0.date) }
        return groups
            .map { (day: $0.key, records: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    private var earliestDate: Date? {
        records.map(\.date).min()
    }

    var body: some View {
        if recordsByDay.isEmpty {
            Text("No reading history yet.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        } else {
            let allDays = recordsByDay
            let visibleDays = showAll ? allDays : Array(allDays.prefix(defaultDayCount))

            VStack(alignment: .leading, spacing: 16) {

                ForEach(visibleDays, id: \.day) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.day.formatted(date: .long, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.textSecondary)

                        ForEach(group.records, id: \.persistentModelID) { record in
                            LoggedReadCard(
                                record: record,
                                bookName: bookName(record.canonicalKey),
                                theme: theme
                            )
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
                            .foregroundColor(theme.accent)
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

    let record: ReadingRecord
    let bookName: String
    let theme: Theme

    @State private var showingDatePicker = false
    @State private var pickedDate = Date()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.subheadline)
                .foregroundColor(theme.accent)

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
                    modelContext.delete(record)
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
