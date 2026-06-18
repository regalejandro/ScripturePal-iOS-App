//
//  CurrentlyReading.swift
//  ScriptureGo
//
//  Tracks which books the user is currently reading, keyed by canonicalKey so
//  it stays translation-independent (like ReadingRecord and CustomGroup).
//

import Foundation
import SwiftData

@Model
final class CurrentlyReading {

    @Attribute(.unique) var canonicalKey: String
    var addedAt: Date

    init(canonicalKey: String) {
        self.canonicalKey = canonicalKey
        self.addedAt = .now
    }
}
