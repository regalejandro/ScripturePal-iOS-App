//
//  BookCompletion.swift
//  ScriptureGo
//
//  Lifetime count of how many times a book has been read cover-to-cover in a
//  reading session. Keyed by canonicalKey (translation-independent). May later
//  feed into Stats.
//

import Foundation
import SwiftData

@Model
final class BookCompletion {

    @Attribute(.unique) var canonicalKey: String
    var count: Int

    init(canonicalKey: String, count: Int = 0) {
        self.canonicalKey = canonicalKey
        self.count = count
    }
}
