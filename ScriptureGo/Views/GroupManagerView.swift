//
//  GroupManagerView.swift
//  ScriptureGo
//
//  Manage categorization groups: view default groups (read-only) and create,
//  edit, or delete custom user groups. Reachable from BookDetailView,
//  SettingsView, and GroupSelectionView.
//

import SwiftUI
import SwiftData

struct GroupManagerView: View {

    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var bible = BibleManager()

    @Query(sort: \CustomGroup.createdAt) private var customGroups: [CustomGroup]

    /// When presented as a sheet, provides the top-right close action.
    var onClose: (() -> Void)?

    @State private var booksContext: GroupBooksContext?
    @State private var showingNewGroup = false
    @State private var newGroupName = ""

    private var theme: Theme { themeManager.current }
    private var allBooks: [Book] { bible.books(for: selectedTranslation) }
    private var defaultGroups: [String] { bible.groups(for: selectedTranslation) }

    var body: some View {
        List {

            // MARK: Default groups
            Section("Default Groups") {
                ForEach(defaultGroups, id: \.self) { group in
                    Button {
                        booksContext = .defaultGroup(group)
                    } label: {
                        groupRow(name: group, count: bookCount(forDefault: group))
                    }
                }
            }
            .foregroundColor(theme.textPrimary)

            // MARK: Custom groups
            Section("Custom Groups") {
                if customGroups.isEmpty {
                    Text("No custom groups yet.")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                } else {
                    ForEach(customGroups) { group in
                        Button {
                            booksContext = .custom(group)
                        } label: {
                            groupRow(name: group.name, count: group.bookKeys.count)
                        }
                    }
                    .onDelete(perform: deleteCustomGroups)
                }

                Button {
                    newGroupName = ""
                    showingNewGroup = true
                } label: {
                    Label("New Group", systemImage: "plus.circle.fill")
                        .foregroundColor(theme.accent)
                }
            }
            .foregroundColor(theme.textPrimary)
        }
        .navigationTitle("Manage Groups")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newGroupName = ""
                    showingNewGroup = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(theme.accent)
            }
            if let onClose {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .sheet(item: $booksContext) { context in
            GroupBooksSheet(context: context, allBooks: allBooks)
                .environmentObject(themeManager)
        }
        .alert("New Group", isPresented: $showingNewGroup) {
            TextField("Group name", text: $newGroupName)
            Button("Create") { createGroup() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Name your custom group.")
        }
    }

    // MARK: - Row

    private func groupRow(name: String, count: Int) -> some View {
        HStack {
            Text(name)
                .foregroundColor(theme.textPrimary)
            Spacer()
            Text("\(count) \(count == 1 ? "book" : "books")")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.textSecondary.opacity(0.6))
        }
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func bookCount(forDefault group: String) -> Int {
        allBooks.filter { $0.groups.contains(group) }.count
    }

    private func createGroup() {
        let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(CustomGroup(name: trimmed))
        newGroupName = ""
    }

    private func deleteCustomGroups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(customGroups[index])
        }
    }
}

// MARK: - GroupBooksContext

/// Identifies which group's books to present in the sheet.
private enum GroupBooksContext: Identifiable {
    case defaultGroup(String)
    case custom(CustomGroup)

    var id: String {
        switch self {
        case .defaultGroup(let name): return "default-\(name)"
        case .custom(let group):      return "custom-\(group.uuid.uuidString)"
        }
    }
}

// MARK: - GroupBooksSheet

/// Lists the books contained in a group. Custom groups allow removing books.
private struct GroupBooksSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let context: GroupBooksContext
    let allBooks: [Book]

    private var theme: Theme { themeManager.current }

    private var title: String {
        switch context {
        case .defaultGroup(let name): return name
        case .custom(let group):      return group.name
        }
    }

    private var isEditable: Bool {
        if case .custom = context { return true }
        return false
    }

    private var books: [Book] {
        switch context {
        case .defaultGroup(let name):
            return allBooks.filter { $0.groups.contains(name) }
        case .custom(let group):
            let keys = Set(group.bookKeys)
            return allBooks.filter { keys.contains($0.canonicalKey) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if books.isEmpty {
                    Text(isEditable
                         ? "No books yet. Add books from a book's detail page."
                         : "No books in this group.")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                } else if isEditable {
                    ForEach(books) { book in
                        bookRow(book)
                    }
                    .onDelete(perform: removeBooks)
                } else {
                    ForEach(books) { book in
                        bookRow(book)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .sheetCloseButton { dismiss() }
        }
    }

    private func bookRow(_ book: Book) -> some View {
        HStack {
            Text(book.name)
                .foregroundColor(theme.textPrimary)
            Spacer()
            Text(book.section)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }

    private func removeBooks(at offsets: IndexSet) {
        guard case .custom(let group) = context else { return }
        let toRemove = offsets.map { books[$0].canonicalKey }
        for key in toRemove {
            group.remove(key)
        }
    }
}
