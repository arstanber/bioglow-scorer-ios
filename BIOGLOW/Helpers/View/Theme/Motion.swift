//
//  Motion.swift
//  BIOGLOW
//
//  Small animations shared by every theme.
//

import SwiftUI

// MARK: - Pressable

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { .init() }
}

// MARK: - Pulse

/// A looping glow and scale, e.g. in the final seconds.
struct Pulse: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let active: Bool
    let color: Color

    func body(content: Content) -> some View {
        if active && !reduceMotion {
            content
                .phaseAnimator([false, true]) { view, on in
                    view
                        .scaleEffect(on ? 1.05 : 1)
                        .shadow(
                            color: color.opacity(on ? 0.8 : 0.2),
                            radius: on ? 10 : 2
                        )
                } animation: { _ in
                    .easeInOut(duration: 0.9)
                }
        } else {
            content
        }
    }
}

// MARK: - Burst

/// A little burst of sparks when `trigger` turns on, e.g. when a mission is completed.
struct Burst: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let trigger: Bool
    let color: Color

    @State private var count: Int = 0

    private static let particles = 10

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 1.0, trigger: count) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                MoveKeyframe(1)
                SpringKeyframe(1.15, duration: 0.15)
                SpringKeyframe(1, duration: 0.35)
            }
            .overlay {
                if !reduceMotion {
                    ZStack {
                        ForEach(0..<Self.particles, id: \.self) { index in
                            particle(index)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .onChange(of: trigger) { old, new in
                if new && !old {
                    count += 1
                }
            }
    }

    private func particle(_ index: Int) -> some View {
        let angle = Double(index) / Double(Self.particles) * 2 * .pi

        return Image(systemName: "sparkles")
            .font(.system(size: 7))
            .foregroundStyle(color)
            .keyframeAnimator(initialValue: 1.0, trigger: count) {
                view,
                progress in
                view
                    .offset(
                        x: cos(angle) * 44 * progress,
                        y: sin(angle) * 26 * progress
                    )
                    .scaleEffect(1 - progress * 0.5)
                    .opacity(progress >= 1 ? 0 : 1 - progress)
            } keyframes: { _ in
                MoveKeyframe(0)
                CubicKeyframe(1, duration: 0.7)
            }
    }
}

extension View {
    func pulse(_ active: Bool, color: Color = .glow) -> some View {
        modifier(Pulse(active: active, color: color))
    }

    func burst(on trigger: Bool, color: Color = .glow) -> some View {
        modifier(Burst(trigger: trigger, color: color))
    }

    /// Marks the source of a zoom transition (iOS 18+).
    @ViewBuilder
    func zoomSource(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Zooms a presentation out of the matching `zoomSource` (iOS 18+).
    @ViewBuilder
    func zoomTransition(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
