//
//  CurrentlyReading.swift
//  ScripturePal
//
//  Tracks which books the user is currently reading, keyed by canonicalKey so
//  it stays translation-independent (like ReadingRecord and CustomGroup).
//
//  The session itself isn't stored here: which chapters count toward it is
//  derived live from ReadingRecord entries dated at/after `addedAt`, so
//  editing or deleting a logged read automatically keeps the session in sync
//  (see BookDetailView/SelectorView's session helpers).
//

import Foundation
import SwiftData

@Model
final class CurrentlyReading {

    @Attribute(.unique) var canonicalKey: String

    /// Start of the current reading session. Reads logged before this date
    /// don't count toward it. Reset to `.now` on "Read Again".
    var addedAt: Date

    /// True once every chapter has been covered this session and the user has
    /// acknowledged the completion (chose to stay in the session). Prevents
    /// re-alerting and drives the Read Again / Remove buttons.
    var completed: Bool = false

    init(canonicalKey: String) {
        self.canonicalKey = canonicalKey
        self.addedAt = .now
        self.completed = false
    }
}
