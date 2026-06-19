//
//  BookCompletion.swift
//  ScriptureGo
//
//  One row per cover-to-cover completion of a book (one per finished reading
//  session, or one per read of a single-chapter book). Keyed by canonicalKey
//  (translation-independent). `timesRead` for a book is the count of its rows.
//
//  Each row remembers exactly which ReadingRecord entries satisfied it
//  (contributingRecordIDs). If any of those records is later deleted, the
//  completion is no longer valid and the row is deleted too — see the
//  deletion handling in ReadingLogView's LoggedReadCard. May later feed into
//  Stats.
//

import Foundation
import SwiftData

@Model
final class BookCompletion {

    var canonicalKey: String = ""
    var completedAt: Date = Date.now
    var contributingRecordIDs: [UUID] = []

    init(canonicalKey: String, completedAt: Date = .now, contributingRecordIDs: [UUID]) {
        self.canonicalKey = canonicalKey
        self.completedAt = completedAt
        self.contributingRecordIDs = contributingRecordIDs
    }
}
