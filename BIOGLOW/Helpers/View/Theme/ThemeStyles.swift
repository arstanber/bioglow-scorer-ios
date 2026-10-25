//
//  ThemeStyles.swift
//  BIOGLOW
//
//  Theme-aware replacements for the hand-rolled gradient, material and
//  selection backgrounds.
//

import SwiftUI

// MARK: - Tile

/// A large colored button or card, like the home screen tiles.
struct ThemedTile: ViewModifier {
    @CurrentTheme private var theme

    let color: Color
    let shape: UnevenRoundedRectangle
    /// Overrides `color.gradient` as the fill, e.g. with the brand gradient.
    var fill: AnyShapeStyle?
    var ink: Color = .white

    private var tileFill: AnyShapeStyle {
        fill ?? AnyShapeStyle(color.gradient)
    }

    func body(content: Content) -> some View {
        switch theme {
        case .firefly:
            content
                .foregroundStyle(ink)
                .background {
                    ZStack {
                        Rectangle().fill(tileFill)

                        FireflyPattern(spacing: 34)
                            .fill(.white.opacity(0.14))

                        LinearGradient(
                            colors: [.white.opacity(0.22), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    }
                    .drawingGroup()
                }
                .clipShape(shape)
                .shadow(color: color.opacity(0.35), radius: 8, y: 4)
        case .liquidGlass:
            if #available(iOS 26.0, *) {
                content
                    .foregroundStyle(ink)
                    .glassEffect(
                        .regular.tint(color.opacity(0.75)).interactive(),
                        in: shape
                    )
            } else {
                content
                    .foregroundStyle(ink)
                    .background(color.opacity(0.6).gradient)
                    .background(.ultraThinMaterial)
                    .clipShape(shape)
                    .overlay(shape.stroke(.white.opacity(0.35), lineWidth: 1))
            }
        case .arena:
            content
                .foregroundStyle(.white)
                .background {
                    ZStack {
                        Color(white: 0.07)

                        RadialGradient(
                            colors: [color.opacity(0.45), .clear],
                            center: .bottomLeading,
                            startRadius: 0,
                            endRadius: 420
                        )
                    }
                }
                .clipShape(shape)
                .overlay(shape.stroke(tileFill, lineWidth: 2))
                .shadow(color: color.opacity(0.55), radius: 10)
        }
    }
}

// MARK: - Surface

/// A neutral panel, optionally tinted, like the scoring panels and cards.
struct ThemedSurface: ViewModifier {
    @CurrentTheme private var theme

    let shape: UnevenRoundedRectangle
    let tint: Color?

    func body(content: Content) -> some View {
        switch theme {
        case .firefly:
            content
                .background((tint ?? .glow).opacity(tint == nil ? 0.05 : 0.2).gradient)
                .background(.ultraThinMaterial)
                .clipShape(shape)
                .overlay(
                    shape.stroke((tint ?? .glow).opacity(0.22), lineWidth: 1)
                )
        case .liquidGlass:
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(
                        .regular.tint(tint?.opacity(0.3)),
                        in: shape
                    )
            } else {
                content
                    .background((tint ?? .clear).opacity(0.2).gradient)
                    .background(.ultraThinMaterial)
                    .clipShape(shape)
                    .overlay(shape.stroke(.white.opacity(0.25), lineWidth: 1))
            }
        case .arena:
            content
                .background((tint ?? .clear).opacity(0.18).gradient)
                .background(Color.white.opacity(0.06))
                .clipShape(shape)
                .overlay(
                    shape.stroke(
                        (tint ?? .white).opacity(tint == nil ? 0.1 : 0.5),
                        lineWidth: 1
                    )
                )
        }
    }
}

// MARK: - Selection

/// The fill behind a selectable control; replaces a plain background.
struct ThemedSelectionFill: ViewModifier {
    @CurrentTheme private var theme

    let selected: Bool
    let base: AnyShapeStyle

    func body(content: Content) -> some View {
        switch theme {
        case .firefly:
            content
                .foregroundStyle(selected ? Color.brandInk : .primary)
                .background {
                    if selected {
                        ZStack {
                            Rectangle().fill(.brand)
                            FireflyPattern(spacing: 16)
                                .fill(.white.opacity(0.15))
                        }
                    }
                }
                .background(base)
        case .liquidGlass:
            content
                .background(
                    Rectangle().fill((selected ? Color.primary : .clear).gradient)
                        .colorInvert()
                )
                .background(base)
                .colorInvert(selected)
        case .arena:
            content
                .foregroundStyle(selected ? .black : .primary)
                .background {
                    if selected {
                        Rectangle().fill(Color.firefly.gradient)
                    }
                }
                .background(Color.white.opacity(0.08))
        }
    }
}

// MARK: - Badge

/// A small status badge: capsules in Firefly, glowing capsules in Arena.
struct ThemedBadge<S: ShapeStyle>: ViewModifier {
    @CurrentTheme private var theme

    let fill: S
    let glow: Color?

    func body(content: Content) -> some View {
        switch theme {
        case .firefly:
            content
                .padding(.horizontal, 4)
                .background(fill, in: Capsule())
        case .liquidGlass:
            content
                .background(fill, in: Capsule())
        case .arena:
            content
                .background(fill, in: Capsule())
                .shadow(color: (glow ?? .clear).opacity(0.8), radius: 6)
        }
    }
}

// MARK: - Score digits

struct ScoreDigits: ViewModifier {
    @CurrentTheme private var theme

    let size: CGFloat
    let weight: Font.Weight
    let glow: Color?

    func body(content: Content) -> some View {
        content
            .font(
                .system(
                    size: size,
                    weight: theme == .arena ? .heavy : weight,
                    design: theme.digitDesign
                )
            )
            .monospacedDigit()
            .shadow(
                color: theme == .arena ? (glow ?? .white).opacity(0.7) : .clear,
                radius: theme == .arena ? 8 : 0
            )
    }
}

extension View {
    func themedTile(
        _ color: Color,
        radius: CGFloat = 16,
        deviceCorners: Set<CornerRadiusViewModifier.Corner> = []
    ) -> some View {
        modifier(
            ThemedTile(
                color: color,
                shape: .tile(radius, deviceCorners: deviceCorners)
            )
        )
    }

    /// A tile in the brand gradient, for the app's primary surfaces.
    func themedBrandTile(
        radius: CGFloat = 16,
        deviceCorners: Set<CornerRadiusViewModifier.Corner> = []
    ) -> some View {
        modifier(
            ThemedTile(
                color: .glow,
                shape: .tile(radius, deviceCorners: deviceCorners),
                fill: AnyShapeStyle(.brand(from: .topLeading, to: .bottomTrailing)),
                ink: .brandInk
            )
        )
    }

    func themedSurface(
        _ radius: CGFloat = 12,
        tint: Color? = nil,
        deviceCorners: Set<CornerRadiusViewModifier.Corner> = []
    ) -> some View {
        modifier(
            ThemedSurface(
                shape: .tile(radius, deviceCorners: deviceCorners),
                tint: tint
            )
        )
    }

    func themedBadge(_ fill: some ShapeStyle, glow: Color? = nil) -> some View {
        modifier(ThemedBadge(fill: fill, glow: glow))
    }

    func scoreDigits(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        glow: Color? = nil
    ) -> some View {
        modifier(ScoreDigits(size: size, weight: weight, glow: glow))
    }
}
