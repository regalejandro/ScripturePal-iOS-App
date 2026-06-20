//
//  ThemeSelection.swift
//  ScripturePal
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
    case noTheme
    case childlike
    case dawn
    case inkVellum
    case meadow
    case miracle
    case moonlight
    case parchment
    case wilderness
    

    /// User-facing name (rawValue is the stored key).
    var displayName: String {
        switch self {
        case .noTheme:      return "No Theme"
        case .parchment:    return "Parchment"
        case .meadow:       return "Meadow"
        case .moonlight:    return "Moonlight"
        case .miracle:      return "Miracle"
        case .childlike:    return "Childlike"
        case .wilderness:   return "Wilderness"
        case .inkVellum:    return "Ink & Vellum"
        case .dawn:         return "Dawn"
        }
    }

    // Light variant
    var light: AppThemeVariant {
        switch self {
        case .noTheme:      return .noTheme
        case .parchment:    return .parchment
        case .meadow:       return .meadow
        case .moonlight:    return .moonlight
        case .childlike:    return .childlike
        case .miracle:      return .miracle
        case .wilderness:   return .wilderness
        case .inkVellum:    return .inkVellum
        case .dawn:         return .dawn
        }
    }

    // Dark variant
    var dark: AppThemeVariant {
        switch self {
        case .noTheme:      return .noTheme
        case .parchment:    return .parchmentDark
        case .meadow:       return .meadowDark
        case .moonlight:    return .moonlightDark
        case .childlike:    return .childlikeDark
        case .miracle:      return .miracleDark
        case .wilderness:   return .wildernessDark
        case .inkVellum:    return .inkVellumDark
        case .dawn:         return .dawnDark
        }
    }
}

enum AppThemeVariant {
    case noTheme
    case parchment
    case parchmentDark
    case meadow
    case meadowDark
    case childlike
    case childlikeDark
    case miracle
    case miracleDark
    case moonlight
    case moonlightDark
    case wilderness
    case wildernessDark
    case inkVellum
    case inkVellumDark
    case dawn
    case dawnDark

    var theme: Theme {
        switch self {

        // MARK: - No Theme (system colors)
        case .noTheme:
            return Theme(
                primary: Color(.systemBlue),
                secondary: Color(.systemGray4),
                background: Color(.systemBackground),
                textPrimary: Color(.label),
                textSecondary: Color(.secondaryLabel),
                accent: Color(.systemBlue),
                warning: Color(.systemRed)
            )

        // MARK: - Parchment
        case .parchment:
            return Theme(
                primary: Color(red: 135/255, green: 90/255, blue: 60/255),     // warm brown
                secondary: Color(red: 220/255, green: 205/255, blue: 190/255), // aged linen
                background: Color(red: 245/255, green: 235/255, blue: 220/255),// antique parchment
                textPrimary: Color(red: 60/255, green: 55/255, blue: 50/255),
                textSecondary: Color(red: 120/255, green: 115/255, blue: 110/255),
                accent: Color(red: 110/255, green: 125/255, blue: 90/255),     // muted olive green
                warning: Color(red: 165/255, green: 75/255, blue: 60/255)      // burnt sienna
            )
        case .parchmentDark:
            return Theme(
                primary: Color(red: 175/255, green: 130/255, blue: 90/255),    // warm tan
                secondary: Color(red: 60/255, green: 50/255, blue: 42/255),    // dark espresso
                background: Color(red: 28/255, green: 24/255, blue: 20/255),   // near-black brown
                textPrimary: Color(red: 235/255, green: 228/255, blue: 215/255),
                textSecondary: Color(red: 185/255, green: 175/255, blue: 165/255),
                accent: Color(red: 150/255, green: 165/255, blue: 120/255),    // sage green
                warning: Color(red: 190/255, green: 90/255, blue: 70/255)      // muted red-orange
            )
            
        // MARK: - Meadow
        case .meadow:
            return Theme(
                primary: Color(red: 155/255, green: 195/255, blue: 225/255),   // soft sky blue
                secondary: Color(red: 195/255, green: 220/255, blue: 200/255), // pale mint green
                background: Color(red: 250/255, green: 246/255, blue: 240/255),// warm white
                textPrimary: Color(red: 60/255, green: 65/255, blue: 70/255),
                textSecondary: Color(red: 110/255, green: 115/255, blue: 120/255),
                accent: Color(red: 235/255, green: 170/255, blue: 195/255),    // soft blush pink
                warning: Color(red: 200/255, green: 95/255, blue: 110/255)     // rose red
            )
        case .meadowDark:
            return Theme(
                primary: Color(red: 115/255, green: 145/255, blue: 180/255),   // muted steel blue
                secondary: Color(red: 55/255, green: 70/255, blue: 60/255),    // dark forest green
                background: Color(red: 20/255, green: 26/255, blue: 24/255),   // deep night green
                textPrimary: Color(red: 225/255, green: 232/255, blue: 235/255),
                textSecondary: Color(red: 170/255, green: 178/255, blue: 180/255),
                accent: Color(red: 205/255, green: 145/255, blue: 170/255),    // dusty mauve
                warning: Color(red: 185/255, green: 85/255, blue: 100/255)     // deep rose
            )
            
        // MARK: - Moonlight
        case .moonlight:
            return Theme(
                primary: Color(red: 90/255, green: 110/255, blue: 160/255),    // slate indigo
                secondary: Color(red: 160/255, green: 180/255, blue: 215/255), // pale periwinkle
                background: Color(red: 242/255, green: 245/255, blue: 250/255),// cool moonlit white
                textPrimary: Color(red: 35/255, green: 45/255, blue: 65/255),
                textSecondary: Color(red: 90/255, green: 100/255, blue: 120/255),
                accent: Color(red: 215/255, green: 190/255, blue: 120/255),    // soft gold
                warning: Color(red: 170/255, green: 85/255, blue: 95/255)      // muted crimson
            )

        case .moonlightDark:
            return Theme(
                primary: Color(red: 120/255, green: 140/255, blue: 190/255),   // cool cornflower blue
                secondary: Color(red: 40/255, green: 55/255, blue: 85/255),    // deep navy
                background: Color(red: 18/255, green: 22/255, blue: 32/255),   // near-black midnight
                textPrimary: Color(red: 230/255, green: 235/255, blue: 245/255),
                textSecondary: Color(red: 160/255, green: 170/255, blue: 190/255),
                accent: Color(red: 220/255, green: 195/255, blue: 135/255),    // warm gold
                warning: Color(red: 190/255, green: 95/255, blue: 105/255)     // muted rose red
            )

        // MARK: - Miracle
        case .miracle:
            return Theme(
                primary: Color(red: 110/255, green: 35/255, blue: 80/255),     // deep grape/burgundy
                secondary: Color(red: 195/255, green: 170/255, blue: 210/255), // soft lavender
                background: Color(red: 252/255, green: 246/255, blue: 238/255),// warm cream
                textPrimary: Color(red: 45/255, green: 20/255, blue: 35/255),
                textSecondary: Color(red: 120/255, green: 90/255, blue: 105/255),
                accent: Color(red: 205/255, green: 160/255, blue: 60/255),     // golden chalice
                warning: Color(red: 180/255, green: 60/255, blue: 55/255)
            )

        case .miracleDark:
            return Theme(
                primary: Color(red: 170/255, green: 90/255, blue: 145/255),    // luminous grape
                secondary: Color(red: 65/255, green: 30/255, blue: 70/255),    // deep violet
                background: Color(red: 20/255, green: 10/255, blue: 24/255),   // dark plum night
                textPrimary: Color(red: 240/255, green: 228/255, blue: 238/255),
                textSecondary: Color(red: 185/255, green: 160/255, blue: 180/255),
                accent: Color(red: 215/255, green: 170/255, blue: 70/255),     // warm gold chalice
                warning: Color(red: 195/255, green: 75/255, blue: 70/255)
            )
            
        // MARK: - Childlike
        case .childlike:
            return Theme(
                primary: Color(red: 60/255, green: 150/255, blue: 220/255),    // crayon sky blue
                secondary: Color(red: 105/255, green: 190/255, blue: 125/255), // grass green
                background: Color(red: 250/255, green: 250/255, blue: 247/255),// soft cloud white
                textPrimary: Color(red: 50/255, green: 55/255, blue: 65/255),
                textSecondary: Color(red: 120/255, green: 125/255, blue: 135/255),
                accent: Color(red: 245/255, green: 175/255, blue: 55/255),     // sunny gold
                warning: Color(red: 225/255, green: 75/255, blue: 70/255)      // cherry red
            )

        case .childlikeDark:
            return Theme(
                primary: Color(red: 85/255, green: 165/255, blue: 235/255),    // bright sky blue
                secondary: Color(red: 85/255, green: 170/255, blue: 105/255),  // grass green
                background: Color(red: 22/255, green: 26/255, blue: 42/255),   // blueberry navy night
                textPrimary: Color(red: 240/255, green: 242/255, blue: 250/255),
                textSecondary: Color(red: 175/255, green: 182/255, blue: 200/255),
                accent: Color(red: 245/255, green: 185/255, blue: 75/255),     // sunny gold
                warning: Color(red: 235/255, green: 90/255, blue: 85/255)      // cherry red
            )

        // MARK: - Wilderness
        case .wilderness:
            return Theme(
                primary: Color(red: 180/255, green: 95/255, blue: 60/255),     // burnt terracotta
                secondary: Color(red: 225/255, green: 210/255, blue: 185/255), // pale sand
                background: Color(red: 248/255, green: 242/255, blue: 230/255),// warm bone
                textPrimary: Color(red: 70/255, green: 55/255, blue: 45/255),
                textSecondary: Color(red: 130/255, green: 110/255, blue: 95/255),
                accent: Color(red: 95/255, green: 150/255, blue: 175/255),     // desert-sky blue
                warning: Color(red: 170/255, green: 70/255, blue: 50/255)      // clay red
            )

        case .wildernessDark:
            return Theme(
                primary: Color(red: 200/255, green: 120/255, blue: 80/255),    // warm terracotta
                secondary: Color(red: 60/255, green: 48/255, blue: 38/255),    // dark umber
                background: Color(red: 26/255, green: 22/255, blue: 18/255),   // deep brown-black
                textPrimary: Color(red: 238/255, green: 228/255, blue: 215/255),
                textSecondary: Color(red: 185/255, green: 168/255, blue: 150/255),
                accent: Color(red: 120/255, green: 170/255, blue: 195/255),    // dusty sky blue
                warning: Color(red: 195/255, green: 90/255, blue: 65/255)      // clay
            )

        // MARK: - Ink & Vellum
        case .inkVellum:
            return Theme(
                primary: Color(red: 55/255, green: 52/255, blue: 48/255),      // charcoal ink
                secondary: Color(red: 205/255, green: 200/255, blue: 192/255), // soft gray
                background: Color(red: 245/255, green: 240/255, blue: 230/255),// cream vellum
                textPrimary: Color(red: 40/255, green: 38/255, blue: 35/255),
                textSecondary: Color(red: 110/255, green: 105/255, blue: 98/255),
                accent: Color(red: 160/255, green: 50/255, blue: 45/255),      // sealing-wax red
                warning: Color(red: 150/255, green: 75/255, blue: 45/255)      // rust
            )

        case .inkVellumDark:
            return Theme(
                primary: Color(red: 215/255, green: 210/255, blue: 200/255),   // pale ink on dark
                secondary: Color(red: 55/255, green: 53/255, blue: 50/255),    // dark gray
                background: Color(red: 22/255, green: 21/255, blue: 20/255),   // near-black
                textPrimary: Color(red: 235/255, green: 232/255, blue: 225/255),
                textSecondary: Color(red: 160/255, green: 156/255, blue: 148/255),
                accent: Color(red: 200/255, green: 80/255, blue: 70/255),      // bright wax red
                warning: Color(red: 185/255, green: 100/255, blue: 65/255)     // rust
            )

        // MARK: - Dawn
        case .dawn:
            return Theme(
                primary: Color(red: 190/255, green: 110/255, blue: 130/255),   // rose-mauve
                secondary: Color(red: 245/255, green: 215/255, blue: 200/255), // blush peach
                background: Color(red: 252/255, green: 245/255, blue: 242/255),// warm blush-white
                textPrimary: Color(red: 75/255, green: 55/255, blue: 60/255),
                textSecondary: Color(red: 140/255, green: 110/255, blue: 115/255),
                accent: Color(red: 225/255, green: 165/255, blue: 95/255),     // sunrise gold
                warning: Color(red: 210/255, green: 95/255, blue: 90/255)      // coral
            )

        case .dawnDark:
            return Theme(
                primary: Color(red: 200/255, green: 130/255, blue: 150/255),   // soft rose
                secondary: Color(red: 60/255, green: 45/255, blue: 52/255),    // deep plum-rose
                background: Color(red: 26/255, green: 20/255, blue: 24/255),   // dusky night
                textPrimary: Color(red: 240/255, green: 228/255, blue: 230/255),
                textSecondary: Color(red: 185/255, green: 160/255, blue: 165/255),
                accent: Color(red: 225/255, green: 170/255, blue: 100/255),    // warm sunrise gold
                warning: Color(red: 215/255, green: 105/255, blue: 100/255)    // coral
            )

        }
    }
}


