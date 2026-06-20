//
//  Haptics.swift
//  ScripturePal
//
//  Centralizes the app's haptic feedback so the same action always feels the
//  same no matter which screen triggers it.
//

import UIKit

enum Haptics {

    /// Subtle tick for confirming a single chapter read was logged.
    static func chapterLogged() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Distinct feedback for adding a book to Currently Reading.
    static func addedToCurrentlyReading() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
