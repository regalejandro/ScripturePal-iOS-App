//
//  CustomGroup.swift
//  ScriptureGo
//
//  A user-created, modifiable categorization group used to filter randomly
//  selected chapters. Membership is stored by canonicalKey so it stays
//  translation-independent, mirroring ReadingRecord.
//

import Foundation
import SwiftData

@Model
final class CustomGroup {

    /// Stable identifier, used to persist filter selections in AppStorage.
    @Attribute(.unique) var uuid: UUID

    /// User-facing group name.
    var name: String

    /// Canonical book keys that belong to this group.
    var bookKeys: [String]

    /// Creation timestamp, used to keep listing order stable.
    var createdAt: Date

    init(name: String, bookKeys: [String] = []) {
        self.uuid = UUID()
        self.name = name
        self.bookKeys = bookKeys
        self.createdAt = .now
    }

    func contains(_ canonicalKey: String) -> Bool {
        bookKeys.contains(canonicalKey)
    }

    func add(_ canonicalKey: String) {
        guard !bookKeys.contains(canonicalKey) else { return }
        bookKeys.append(canonicalKey)
    }

    func remove(_ canonicalKey: String) {
        bookKeys.removeAll { $0 == canonicalKey }
    }
}
