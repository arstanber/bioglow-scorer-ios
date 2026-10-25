//
//  ScoringComponents.swift
//  BIOGLOW
//
//  Controls shared by the match scorer and the calculator.
//

import SwiftUI

// MARK: - Styling

extension View {
    func selectionFill(
        _ selected: Bool,
        base: some ShapeStyle = .ultraThinMaterial
    ) -> some View {
        modifier(
            ThemedSelectionFill(selected: selected, base: AnyShapeStyle(base))
        )
    }
}

// MARK: - Selector

/// One option in a row of mutually exclusive choices.
struct SelectorItem<Value: Hashable>: View {
    var icon: String? = nil
    let name: String
    var subtitle: String? = nil
    let value: Value
    @Binding var selection: Value
    var disabled: Bool = false

    var body: some View {
        let selected = selection == value

        VStack(spacing: 2) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                }

                Text(name)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .opacity(0.7)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .maxArea()
        .selectionFill(selected, base: Color.secondary.opacity(0.15))
        .radius(10)
        .opacity(disabled ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !disabled, !selected else { return }
            Haptics.play(.light)
            selection = value
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A row of `SelectorItem`s for a small count, e.g. 0…3 seeds.
struct CountSelector: View {
    @Binding var value: Int
    let max: Int
    /// Points per element, shown under each number.
    var points: Int? = nil
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0...max, id: \.self) { count in
                SelectorItem(
                    name: "\(count)",
                    subtitle: points.map { "\(count * $0)" },
                    value: count,
                    selection: $value,
                    disabled: disabled
                )
            }
        }
    }
}

// MARK: - Toggles

struct ToggleTile: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    var disabled: Bool = false
    /// Draws attention to the tile, e.g. the M15 action the dock bonus needs.
    var highlighted: Bool = false

    var body: some View {
        Button {
            Haptics.play(.light)
            isOn.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isOn ? "checkmark.circle.fill" : icon)
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isOn)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption2)
                    .opacity(0.7)
                    .lineLimit(1)
            }
            .minimumScaleFactor(0.6)
            .padding(6)
            .maxArea()
            .selectionFill(isOn, base: Color.secondary.opacity(0.15))
            .radius(10)
            .overlay {
                if highlighted {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.firefly, lineWidth: 2.5)
                }
            }
        }
        .tint(.primary)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - Badges

/// "+20" in a small capsule, gray at zero.
struct PointsBadge: View {
    let points: Int
    var maxPoints: Int? = nil

    var body: some View {
        Text(maxPoints.map { "\(points)/\($0)" } ?? "\(points)")
            .font(.subheadline)
            .fontWeight(.bold)
            .monospacedDigit()
            .foregroundStyle(points > 0 ? Color.brandInk : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .themedBadge(
                points > 0
                    ? AnyShapeStyle(.brand)
                    : AnyShapeStyle(Color.secondary.opacity(0.15)),
                glow: points > 0 ? .glow : nil
            )
            .contentTransition(.numericText())
            .animation(.smooth, value: points)
    }
}

/// Reminds scorers that equipment may stay in this mission's model.
struct NoEquipmentConstraintBadge: View {
    var body: some View {
        Label("No equipment constraint", systemImage: "shippingbox")
            .font(.caption2)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12), in: Capsule())
    }
}
