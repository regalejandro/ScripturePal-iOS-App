//
//  GlassCompatibility.swift
//  ScripturePal
//
//  The app's deployment target is iOS 17, but Liquid Glass (.glassProminent,
//  .glassEffect) only exists on iOS 26+. These wrappers apply the real glass
//  styling when it's available and fall back to a close pre-26 equivalent
//  everywhere else, so the four call sites that want glass don't each need
//  their own #available branch.
//

import SwiftUI

extension View {

    /// `.glassProminent` button style on iOS 26+; `.borderedProminent` (still
    /// a filled, tinted "primary action" look) on earlier versions.
    @ViewBuilder
    func glassProminentOrFallback(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent).tint(tint)
        } else {
            self.buttonStyle(.borderedProminent).tint(tint)
        }
    }

    /// `.glassEffect` in a circle on iOS 26+; a frosted-material circle on
    /// earlier versions as the closest pre-Liquid-Glass equivalent.
    @ViewBuilder
    func glassCircleOrFallback() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: Circle())
        } else {
            self
                .background(Circle().fill(.thinMaterial))
                .clipShape(Circle())
        }
    }
}
