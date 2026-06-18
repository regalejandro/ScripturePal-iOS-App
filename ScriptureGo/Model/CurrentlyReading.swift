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

    /// Chapters read during the current reading session.
    var sessionChapters: [Int] = []

    /// True once every chapter has been read this session and the user has
    /// acknowledged the completion (chose to stay in the session). Prevents
    /// re-alerting and drives the Read Again / Remove buttons.
    var completed: Bool = false

    init(canonicalKey: String) {
        self.canonicalKey = canonicalKey
        self.addedAt = .now
        self.sessionChapters = []
        self.completed = false
    }

    func markSessionRead(_ chapter: Int) {
        guard !sessionChapters.contains(chapter) else { return }
        sessionChapters.append(chapter)
    }

    /// Number of distinct in-range chapters read this session.
    func sessionReadCount(totalChapters: Int) -> Int {
        Set(sessionChapters).intersection(1...max(1, totalChapters)).count
    }
}
