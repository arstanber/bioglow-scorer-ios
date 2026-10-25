//
//  GlassBackground.swift
//  BIOGLOW
//
//  Created by Jining Liu on 9/9/25.
//

import SwiftUI

struct GlassBackground: ViewModifier {
    @CurrentTheme private var theme

    let shape: any Shape

    func body(content: Content) -> some View {
        switch theme {
        case .firefly:
            content
                .background(Color.glow.opacity(0.12))
                .background(.ultraThinMaterial)
                .clipShape(AnyShape(shape))
                .overlay(
                    AnyShape(shape).stroke(Color.glow.opacity(0.35), lineWidth: 1)
                )
        case .liquidGlass:
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(in: shape)
            } else {
                content
                    .background(.ultraThinMaterial)
                    .clipShape(AnyShape(shape))
            }
        case .arena:
            content
                .background(Color.white.opacity(0.1))
                .clipShape(AnyShape(shape))
                .overlay(
                    AnyShape(shape).stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        }
    }
}

extension View {
    func glassBackground(shape: any Shape = Capsule()) -> some View {
        modifier(GlassBackground(shape: shape))
    }
}
