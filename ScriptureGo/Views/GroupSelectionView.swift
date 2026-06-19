//
//  GroupSelectionView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 12/1/25.
//

import SwiftUI
import SwiftData

struct GroupSelectionView: View {
    @Binding var selectedGroups: [String]
    @Binding var groupMode: String  // "all" or "custom"

    @Binding var selectedGroupsBackup: [String]
    /// Selected custom groups, stored by CustomGroup.uuid.uuidString.
    @Binding var selectedCustomGroups: [String]
    /// Whether books on the Currently Reading list are included in the selection.
    @Binding var includeCurrentlyReading: Bool

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomGroup.createdAt) private var customGroups: [CustomGroup]
    @Query private var currentlyReading: [CurrentlyReading]

    let allGroups: [String]

    private var theme: Theme { themeManager.current }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - MODE SELECTION
                Section("Included Sections") {
                    Button {
                        groupMode = "all"
                        selectedGroupsBackup = selectedGroups
                        selectedGroups = allGroups
                    } label: {
                        HStack {
                            Text("Include All Books")
                            Spacer()
                            if groupMode == "all" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }

                    Button {
                        groupMode = "custom"
                        selectedGroups = selectedGroupsBackup
                    } label: {
                        HStack {
                            Text("Custom Selection")
                            Spacer()
                            if groupMode == "custom" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                }
                .foregroundColor(theme.textPrimary)


                // MARK: - DEFAULT GROUPS
                if groupMode == "custom" {
                    Section("Default Groups") {
                        ForEach(allGroups, id: \.self) { group in
                            Toggle(group, isOn: Binding(
                                get: { selectedGroups.contains(group) },
                                set: { isOn in
                                    if isOn {
                                        if !selectedGroups.contains(group) {
                                            selectedGroups.append(group)
                                        }
                                    } else {
                                        selectedGroups.removeAll { $0 == group }
                                    }
                                }
                            ))
                        }
                    }
                    .foregroundColor(theme.textPrimary)

                    // MARK: - CUSTOM GROUPS
                    Section("Custom Groups") {
                        if customGroups.isEmpty {
                            Text("No custom groups yet.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        } else {
                            ForEach(customGroups) { group in
                                Toggle(group.name, isOn: Binding(
                                    get: { selectedCustomGroups.contains(group.uuid.uuidString) },
                                    set: { isOn in
                                        let id = group.uuid.uuidString
                                        if isOn {
                                            if !selectedCustomGroups.contains(id) {
                                                selectedCustomGroups.append(id)
                                            }
                                        } else {
                                            selectedCustomGroups.removeAll { $0 == id }
                                        }
                                    }
                                ))
                            }
                        }
                    }
                    .foregroundColor(theme.textPrimary)

                    // MARK: - CURRENTLY READING
                    Section("Currently Reading") {
                        if currentlyReading.isEmpty {
                            Text("No books in your reading list yet.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        } else {
                            Toggle("Currently Reading", isOn: $includeCurrentlyReading)
                        }
                    }
                    .foregroundColor(theme.textPrimary)

                    Section {
                        if !allSelected {
                            Button {
                                selectedGroups = allGroups
                                selectedCustomGroups = customGroups.map { $0.uuid.uuidString }
                                includeCurrentlyReading = true
                            } label: {
                                Text("Select All")
                                    .foregroundColor(theme.primary)
                            }
                        }
                        if hasAnySelection {
                            Button {
                                selectedGroups = []
                                selectedCustomGroups = []
                                includeCurrentlyReading = false
                            } label: {
                                Text("Deselect All")
                                    .foregroundColor(theme.warning)
                            }
                        }
                    }
                }

                // MARK: - MANAGE GROUPS
                Section {
                    NavigationLink {
                        GroupManagerView()
                    } label: {
                        Label("Manage Groups", systemImage: "rectangle.3.group")
                    }
                }
                .foregroundColor(theme.textPrimary)
            }
            .navigationTitle("Section Filtering")
            .sheetCloseButton { dismiss() }
        }
    }

    private var allSelected: Bool {
        selectedGroups.count >= allGroups.count
        && selectedCustomGroups.count >= customGroups.count
        && (currentlyReading.isEmpty || includeCurrentlyReading)
    }

    private var hasAnySelection: Bool {
        !selectedGroups.isEmpty || !selectedCustomGroups.isEmpty || includeCurrentlyReading
    }
}
