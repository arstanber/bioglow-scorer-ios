//
//  ThemedBackground.swift
//  BIOGLOW
//

import SwiftUI

struct ThemedBackground: View {
    @CurrentTheme private var theme

    var body: some View {
        Group {
            switch theme {
            case .firefly:
                ZStack {
                    Color(uiColor: .systemBackground)

                    LinearGradient(
                        colors: [
                            .glowBright.opacity(0.18), .glow.opacity(0.1),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    FireflyPattern(spacing: 40)
                        .fill(Color.glow.opacity(0.12))
                }
                .drawingGroup()
            case .liquidGlass:
                if #available(iOS 18.0, *) {
                    MeshBackdrop()
                } else {
                    LinearGradient(
                        colors: [
                            .glow.opacity(0.5), .bark.opacity(0.35),
                            .spore.opacity(0.45),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .background(Color(uiColor: .systemBackground))
                }
            case .arena:
                ZStack {
                    Color(white: 0.03)

                    RadialGradient(
                        colors: [Color(white: 0.13), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 700
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// A slowly drifting mesh of the BIOGLOW colors.
@available(iOS 18.0, *)
private struct MeshBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(
            .animation(minimumInterval: 1 / 20, paused: reduceMotion)
        ) { context in
            MeshGradient(
                width: 3,
                height: 3,
                points: points(
                    at: context.date.timeIntervalSinceReferenceDate / 5
                ),
                colors: [
                    .glow, .firefly, .moss,
                    .bark, .glow, .spore,
                    .qazaqlyPurple, .moss, .glow,
                ]
            )
        }
        .overlay(
            Color(uiColor: .systemBackground)
                .opacity(colorScheme == .dark ? 0.55 : 0.3)
        )
    }

    private func points(at t: TimeInterval) -> [SIMD2<Float>] {
        func wave(_ value: Double, _ amount: Double) -> Float {
            Float(0.5 + amount * value)
        }

        return [
            [0, 0], [wave(sin(t), 0.2), 0], [1, 0],
            [0, wave(cos(t * 0.8), 0.2)],
            [wave(sin(t * 1.3), 0.15), wave(cos(t), 0.15)],
            [1, wave(sin(t * 0.9), 0.2)],
            [0, 1], [wave(cos(t * 1.1), 0.2), 1], [1, 1],
        ]
    }
}
