//
//  DataModel.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/18/25.
//

import Foundation

struct BibleData: Codable {
    let translations: [String: Translation]
}

struct Translation: Codable {
    let tradition: String
    let books: [Book]
}

struct Book: Codable, Identifiable {
    let id: Int
    let name: String
    let chapters: Int
    let groups: [String]
    let section: String
    let canonicalKey: String
}

struct ChapterPointer {
    let bookID: Int
    let bookName: String
    let chapter: Int
    let canonicalKey: String
}
