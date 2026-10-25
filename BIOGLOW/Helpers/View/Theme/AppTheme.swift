//
//  AppTheme.swift
//  BIOGLOW
//
//  The app-wide visual theme, picked in Settings → Appearance.
//

import SwiftUI

enum AppTheme: String, Codable, Hashable, CaseIterable, RawRepresentable {
    case firefly = "Firefly"
    case liquidGlass = "Liquid Glass"
    case arena = "Arena"

    static let storageKey = "appTheme"

    var icon: String {
        switch self {
        case .firefly: "sparkles"
        case .liquidGlass: "drop.fill"
        case .arena: "sportscourt.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .firefly: "Glowing forest colors and drifting fireflies"
        case .liquidGlass: "Tinted glass over a living gradient"
        case .arena: "Dark scoreboard with neon glow"
        }
    }

    /// Arena is always dark; the other themes follow the system.
    var colorScheme: ColorScheme? {
        self == .arena ? .dark : nil
    }

    var fontDesign: Font.Design {
        self == .firefly ? .rounded : .default
    }

    var digitDesign: Font.Design {
        self == .arena ? .monospaced : .rounded
    }
}

extension EnvironmentValues {
    /// Forces a theme for a subtree, e.g. the previews in Settings.
    @Entry var appThemeOverride: AppTheme? = nil
}

/// The theme in effect: the environment override, or the stored setting.
@propertyWrapper
struct CurrentTheme: DynamicProperty {
    @AppStorage(AppTheme.storageKey) private var stored: AppTheme = .firefly
    @Environment(\.appThemeOverride) private var override

    var wrappedValue: AppTheme {
        override ?? stored
    }
}

// MARK: - Root

struct AppThemeRoot: ViewModifier {
    @CurrentTheme private var theme

    func body(content: Content) -> some View {
        content
            .fontDesign(theme.fontDesign)
            .preferredColorScheme(theme.colorScheme)
    }
}

extension View {
    /// Applies the theme's font design and color scheme. Use at the root of every presentation.
    func appThemeRoot() -> some View {
        modifier(AppThemeRoot())
    }

    /// The theme's full-screen background plus `appThemeRoot()`.
    func themedBackground() -> some View {
        background(ThemedBackground())
            .appThemeRoot()
    }
}
