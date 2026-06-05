//
//  ReadingRecord.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 6/4/26.
//

import Foundation
import SwiftData

@Model
final class ReadingRecord {

    // MARK: - Stored Properties
    /// Canonical book identifier, e.g. "genesis", "1-corinthians" (translation-independent)
    var canonicalKey: String

    /// Chapter number within that book (1-based)
    var chapter: Int

    /// Full timestamp of when the user marked this chapter as read.
    /// Use this to derive year, month, or day groupings for stats.
    var date: Date

    // MARK: - Init
    init(canonicalKey: String, chapter: Int, date: Date = .now) {
        self.canonicalKey = canonicalKey
        self.chapter      = chapter
        self.date         = date
    }

    //MARK: - Convenience
    /// The calendar year this record belongs to.
    var year: Int {
        Calendar.current.component(.year, from: date)
    }
}
