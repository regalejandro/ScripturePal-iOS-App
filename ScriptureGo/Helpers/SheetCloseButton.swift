//
//  SheetCloseButton.swift
//  ScriptureGo
//
//  A reusable top-right "X" close button for sheets.
//

import SwiftUI

extension View {
    /// Adds an "X" close button to the top-right of the navigation bar that
    /// runs `action` (typically dismissing the sheet).
    func sheetCloseButton(action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Close")
            }
        }
    }
}
