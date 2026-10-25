//
//  BrandGradient.swift
//  BIOGLOW
//
//  The BIOGLOW brand gradient: GlowBright (#FFDD02) into Glow (#A58205).
//

import SwiftUI

extension ShapeStyle where Self == LinearGradient {
    /// The two-stop brand gradient, running left to right.
    static var brand: LinearGradient {
        .brand(from: .leading, to: .trailing)
    }

    static func brand(
        from startPoint: UnitPoint,
        to endPoint: UnitPoint
    ) -> LinearGradient {
        LinearGradient(
            colors: [.glowBright, .glow],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

extension Color {
    /// Text and icons laid over the brand gradient; white fails on the bright stop.
    static let brandInk = Color(white: 0.1)
}
