//
//  SettingsView.swift
//  BIOGLOW
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var rulesStore: GameRulesStore = .shared

    @AppStorage("soundsEnabled") private var soundsEnabled: Bool = true
    @AppStorage("preserveTeamsAfterResetting") private
        var preserveTeamsAfterResetting: Bool = false
    @AppStorage("preserveTeamsAfterExiting") private
        var preserveTeamsAfterExiting: Bool = false
    @AppStorage(AppTheme.storageKey) private var appTheme: AppTheme = .firefly

    private static let seasonURL = URL(string: "https://www.firstinspires.org/programs/fll/game-and-season")!
    private static let repoURL = URL(string: "https://github.com/arstanber/bioglow-scorer-ios")!
    private static let privacyURL = URL(string: "https://github.com/arstanber/bioglow-scorer-ios/blob/main/PRIVACY.md")!
    private static let supportURL = URL(string: "https://github.com/arstanber/bioglow-scorer-ios/issues")!

    var body: some View {
        NavigationStack {
            List {
                Section {
                } header: {
                    if let warningLabel = BIOGLOW.environment.warningLabel {
                        warningLabel
                    }
                }
                .font(.subheadline)
                .headerProminence(.increased)

                Section {
                    SettingsToggle(
                        title: "Sounds",
                        description: "Play a sound when the match starts and ends",
                        icon: "speaker.wave.2",
                        isOn: $soundsEnabled
                    )

                    HStack {
                        SettingsLabel(
                            title: "Start Delay",
                            description: "Count down before the timer starts, to step back from the robot",
                            icon: "timer"
                        )
                        Spacer()
                        StartDelayPicker()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        SettingsLabel(
                            title: "Preserve Team Number",
                            description: "Keep the team number after resetting or exiting the scorer",
                            icon: "bookmark"
                        )

                        HStack(spacing: 12) {
                            Image(systemName: "bookmark")
                                .font(.title3)
                                .opacity(0)

                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                    .padding(.leading, 32)

                                SettingsToggle(
                                    title: "After Resetting",
                                    icon: "arrow.2.circlepath",
                                    small: true,
                                    isOn: $preserveTeamsAfterResetting
                                )

                                Divider()
                                    .padding(.leading, 32)

                                SettingsToggle(
                                    title: "After Exiting",
                                    icon: "rectangle.portrait.and.arrow.right",
                                    small: true,
                                    isOn: $preserveTeamsAfterExiting
                                )
                            }
                        }
                    }
                } header: {
                    Label("Behavior", systemImage: "rectangle.2.swap")
                }
                .headerProminence(.increased)

                rulesSection

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsLabel(
                            title: "Theme",
                            description: appTheme.subtitle,
                            icon: appTheme.icon
                        )
                        .contentTransition(.opacity)

                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button {
                                    Haptics.play(.light)
                                    withAnimation(.smooth) {
                                        appTheme = theme
                                    }
                                } label: {
                                    ThemePreviewCard(
                                        theme: theme,
                                        selected: appTheme == theme
                                    )
                                }
                                .buttonStyle(.pressable)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .headerProminence(.increased)

                supportSection

                Section {
                } header: {
                    VStack(alignment: .leading) {
                        Text("BIOGLOW™ Scorer")
                        Text("made by **kita 39112**")
                            .font(.subheadline)
                    }
                } footer: {
                    Text(
                        """
                        Version \(version) (\(build))

                        *FIRST*® LEGO® League and BIOGLOW™ are jointly held trademarks of *FIRST*® (For Inspiration and Recognition of Science and Technology) and the LEGO Group.

                        This is an independent project. It is not affiliated with, sponsored or endorsed by *FIRST* or the LEGO Group. Always follow the official Robot Game Rulebook and Challenge Updates.

                        © 2026 kita 39112 and Contributors. MIT License.
                        """
                    )
                }
                .headerProminence(.increased)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DismissButton {
                        dismiss()
                    }
                }
            }
        }
    }

    private var rulesSection: some View {
        Section {
            HStack {
                SettingsLabel(
                    title: rulesStore.rules.source,
                    description: "Revision \(rulesStore.rules.revision) · \(rulesStore.rules.published)",
                    icon: "doc.text"
                )
                Spacer()
                switch rulesStore.status {
                case .checking:
                    ProgressView()
                case .updated:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                default:
                    EmptyView()
                }
            }

            Button {
                Task { await rulesStore.checkForUpdates() }
            } label: {
                SettingsLabel(title: "Check for Rule Updates", icon: "arrow.down.circle")
            }
            .disabled(rulesStore.status == .checking)

            if rulesStore.rules.revision > GameRules.bundled.revision {
                Button(role: .destructive) {
                    rulesStore.resetToBundled()
                } label: {
                    SettingsLabel(title: "Use Rules Shipped with the App", icon: "arrow.uturn.backward")
                }
            }

            Link(destination: Self.seasonURL) {
                SettingsLabel(
                    title: "Robot Game Rulebook",
                    description: "Official BIOGLOW season page",
                    icon: "book.pages"
                )
            }

            Link(destination: Self.seasonURL) {
                SettingsLabel(
                    title: "Challenge Updates",
                    description: "Updates override the rulebook",
                    icon: "exclamationmark.bubble"
                )
            }
        } header: {
            Label("Rules", systemImage: "list.bullet.clipboard")
        } footer: {
            switch rulesStore.status {
            case .updated(let revision):
                Text("Updated to revision \(revision).")
            case .upToDate:
                Text("Scoring is up to date.")
            case .failed(let message):
                Text(message)
            case .idle, .checking:
                if let lastChecked = rulesStore.lastChecked {
                    Text("Last checked \(lastChecked.formatted(.relative(presentation: .named))).")
                } else {
                    Text("Point values can be updated for Challenge Updates without an App Store release.")
                }
            }
        }
        .headerProminence(.increased)
    }

    private var supportSection: some View {
        Section {
            Link(destination: Self.privacyURL) {
                SettingsLabel(
                    title: "Privacy Policy",
                    description: "No accounts or ads; matches stay on your device",
                    icon: "hand.raised"
                )
            }

            Link(destination: Self.supportURL) {
                SettingsLabel(
                    title: "Support & Feedback",
                    description: "Report a scoring issue on GitHub",
                    icon: "lifepreserver"
                )
            }

            Link(destination: Self.repoURL) {
                SettingsLabel(
                    title: "Source Code",
                    description: "MIT License",
                    icon: "chevron.left.forwardslash.chevron.right"
                )
            }
        } header: {
            Label("Privacy & Support", systemImage: "lock.shield")
        }
        .headerProminence(.increased)
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ThemedBackground()

                HStack(spacing: 5) {
                    Color.clear
                        .themedBrandTile(radius: 6)

                    VStack(spacing: 5) {
                        Color.clear
                            .themedTile(.firefly, radius: 6)
                        Color.clear
                            .themedTile(.spore, radius: 6)
                    }
                }
                .padding(7)
            }
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        selected ? Color.accentColor : .secondary.opacity(0.3),
                        lineWidth: selected ? 3 : 1
                    )
            }

            Label(theme.rawValue, systemImage: theme.icon)
                .font(.caption)
                .fontWeight(selected ? .bold : .regular)
                .fontDesign(theme.fontDesign)
                .foregroundStyle(selected ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .environment(\.appThemeOverride, theme)
        .frame(maxWidth: .infinity)
    }
}

struct SettingsToggle: View {
    let title: String
    let description: String?
    let icon: String?
    let small: Bool
    @Binding var isOn: Bool

    init(
        title: String,
        description: String? = nil,
        icon: String? = nil,
        small: Bool = false,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.small = small
        _isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            SettingsLabel(
                title: title,
                description: description,
                icon: icon,
                small: small
            )
        }
    }
}

struct SettingsLabel: View {
    let title: String
    let description: String?
    let icon: String?
    let small: Bool

    init(
        title: String,
        description: String? = nil,
        icon: String? = nil,
        small: Bool = false
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.small = small
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(small ? .body : .title3)
            }

            VStack(alignment: .leading) {
                Text(title)
                    .font(small ? .subheadline : .body)

                if let description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
