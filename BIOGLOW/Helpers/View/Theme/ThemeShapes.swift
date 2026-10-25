//
//  ThemeShapes.swift
//  BIOGLOW
//

import SwiftUI

/// Scattered dots of varying size, like fireflies over the forest floor.
/// The layout is deterministic so it doesn't jump between redraws.
struct FireflyPattern: Shape {
    var spacing: CGFloat = 32

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rowStep = spacing * 0.87

        var row = 0
        var y = rect.minY
        while y < rect.maxY + spacing {
            var column = 0
            var x = rect.minX + (row.isMultiple(of: 2) ? 0 : spacing / 2)
            while x < rect.maxX + spacing {
                let seed = Self.noise(row, column)
                // Leave roughly a third of the grid empty.
                if seed > 0.33 {
                    let radius = spacing * (0.03 + 0.06 * seed)
                    let jitterX = (Self.noise(column, row + 7) - 0.5) * spacing * 0.6
                    let jitterY = (Self.noise(row + 3, column + 11) - 0.5) * spacing * 0.6
                    path.addEllipse(
                        in: CGRect(
                            x: x + jitterX - radius,
                            y: y + jitterY - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                    )
                }
                x += spacing
                column += 1
            }
            y += rowStep
            row += 1
        }

        return path
    }

    /// A stable pseudo-random value in 0..<1 for a grid cell.
    private static func noise(_ a: Int, _ b: Int) -> CGFloat {
        var value = UInt64(truncatingIfNeeded: a &* 73_856_093 ^ b &* 19_349_663)
        value ^= value >> 13
        value = value &* 0x5bd1e995
        value ^= value >> 15
        return CGFloat(value % 1000) / 1000
    }
}

extension UnevenRoundedRectangle {
    /// A rounded rectangle whose `deviceCorners` follow the display's corner radius.
    static func tile(
        _ radius: CGFloat,
        deviceCorners: Set<CornerRadiusViewModifier.Corner> = [],
        fallback: CGFloat = 24,
        subtract: CGFloat = 8
    ) -> UnevenRoundedRectangle {
        let device =
            (UIScreen.main.displayCornerRadius(min: 20)
            ?? (fallback + subtract)) - subtract

        func value(_ corner: CornerRadiusViewModifier.Corner) -> CGFloat {
            deviceCorners.contains(corner) ? device : radius
        }

        return UnevenRoundedRectangle(
            topLeadingRadius: value(.topLeading),
            bottomLeadingRadius: value(.bottomLeading),
            bottomTrailingRadius: value(.bottomTrailing),
            topTrailingRadius: value(.topTrailing),
            style: .continuous
        )
    }
}
