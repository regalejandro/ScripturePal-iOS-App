//
//  ThemeSelection.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 1/14/26.
//

import Foundation
import SwiftUI
import Combine
import UIKit

final class ThemeManager: ObservableObject {

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.parchment.rawValue

    @Published private(set) var current: Theme

    init() {
        let raw =
            UserDefaults.standard.string(forKey: "selectedTheme")
            ?? AppTheme.parchment.rawValue

        let baseTheme = AppTheme(rawValue: raw) ?? .parchment
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        self.current = isDark ? baseTheme.dark.theme : baseTheme.light.theme
    }

    // Apply the correct variant based on system appearance
    func apply(systemScheme: ColorScheme) {
        let baseTheme =
            AppTheme(rawValue: selectedThemeRaw) ?? .parchment

        let variant =
            systemScheme == .dark
                ? baseTheme.dark
                : baseTheme.light

        current = variant.theme
    }

    // Called when the user picks a different theme
    func setBaseTheme(
        _ theme: AppTheme,
        systemScheme: ColorScheme
    ) {
        selectedThemeRaw = theme.rawValue
        apply(systemScheme: systemScheme)
    }
}


struct Theme {
    let primary: Color
    let secondary: Color
    let background: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let warning: Color
}

enum AppTheme: String, CaseIterable {
    case parchment
    case meadow
    case moonlight

    // Light variant
    var light: AppThemeVariant {
        switch self {
        case .parchment: return .parchment
        case .meadow: return .meadow
        case .moonlight: return .moonlight
        }
    }

    // Dark variant
    var dark: AppThemeVariant {
        switch self {
        case .parchment: return .parchmentDark
        case .meadow: return .meadowDark
        case .moonlight: return .moonlightDark
        }
    }
}

enum AppThemeVariant {
    case parchment
    case parchmentDark
    case meadow
    case meadowDark
    case moonlight
    case moonlightDark

    var theme: Theme {
        switch self {
        case .parchment:
            return Theme(
                primary: Color(red: 135/255, green: 90/255, blue: 60/255),
                secondary: Color(red: 220/255, green: 205/255, blue: 190/255),
                background: Color(red: 245/255, green: 235/255, blue: 220/255),
                textPrimary: Color(red: 60/255, green: 55/255, blue: 50/255),
                textSecondary: Color(red: 120/255, green: 115/255, blue: 110/255),
                accent: Color(red: 110/255, green: 125/255, blue: 90/255),
                warning: Color(red: 165/255, green: 75/255, blue: 60/255)
            )
        case .parchmentDark:
            return Theme(
                primary: Color(red: 175/255, green: 130/255, blue: 90/255),
                secondary: Color(red: 60/255, green: 50/255, blue: 42/255),
                background: Color(red: 28/255, green: 24/255, blue: 20/255),
                textPrimary: Color(red: 235/255, green: 228/255, blue: 215/255),
                textSecondary: Color(red: 185/255, green: 175/255, blue: 165/255),
                accent: Color(red: 150/255, green: 165/255, blue: 120/255),
                warning: Color(red: 190/255, green: 90/255, blue: 70/255)
            )
        case .meadow:
            return Theme(
                primary: Color(red: 155/255, green: 195/255, blue: 225/255),
                secondary: Color(red: 195/255, green: 220/255, blue: 200/255),
                background: Color(red: 250/255, green: 246/255, blue: 240/255),
                textPrimary: Color(red: 60/255, green: 65/255, blue: 70/255),
                textSecondary: Color(red: 110/255, green: 115/255, blue: 120/255),
                accent: Color(red: 235/255, green: 170/255, blue: 195/255),
                warning: Color(red: 200/255, green: 95/255, blue: 110/255)
            )
        case .meadowDark:
            return Theme(
                primary: Color(red: 115/255, green: 145/255, blue: 180/255),
                secondary: Color(red: 55/255, green: 70/255, blue: 60/255),
                background: Color(red: 20/255, green: 26/255, blue: 24/255),
                textPrimary: Color(red: 225/255, green: 232/255, blue: 235/255),
                textSecondary: Color(red: 170/255, green: 178/255, blue: 180/255),
                accent: Color(red: 205/255, green: 145/255, blue: 170/255),
                warning: Color(red: 185/255, green: 85/255, blue: 100/255)
            )
            
        case .moonlight:
            return Theme(

                primary: Color(red: 90/255, green: 110/255, blue: 160/255),
                secondary: Color(red: 160/255, green: 180/255, blue: 215/255),
                background: Color(red: 242/255, green: 245/255, blue: 250/255),
                textPrimary: Color(red: 35/255, green: 45/255, blue: 65/255),
                textSecondary: Color(red: 90/255, green: 100/255, blue: 120/255),
                accent: Color(red: 215/255, green: 190/255, blue: 120/255),
                warning: Color(red: 170/255, green: 85/255, blue: 95/255)
            )
            
        case .moonlightDark:
            return Theme(
                primary: Color(red: 120/255, green: 140/255, blue: 190/255),
                secondary: Color(red: 40/255, green: 55/255, blue: 85/255),
                background: Color(red: 18/255, green: 22/255, blue: 32/255),
                textPrimary: Color(red: 230/255, green: 235/255, blue: 245/255),
                textSecondary: Color(red: 160/255, green: 170/255, blue: 190/255),
                accent: Color(red: 220/255, green: 195/255, blue: 135/255),
                warning: Color(red: 190/255, green: 95/255, blue: 105/255)
            )

        }
    }
}


