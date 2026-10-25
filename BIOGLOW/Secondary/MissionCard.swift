//
//  MissionCard.swift
//  BIOGLOW
//
//  One mission's controls and points on the scoring screen.
//

import SwiftUI

struct MissionCard: View {
    let mission: Mission
    @Binding var scores: BioGlowScores

    private var p: GameRules.Points { BioGlowPoints.points }
    private var counts: GameRules.Counts { BioGlowPoints.counts }

    private let toggleHeight: CGFloat = 76
    private let selectorHeight: CGFloat = 48

    var body: some View {
        let points = scores.points(for: mission)
        let maxPoints = mission.maxPoints

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(mission.code)
                    .font(.caption)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .themedBadge(Color.moss.gradient)

                Text(mission.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 4)

                PointsBadge(points: points, maxPoints: maxPoints)
            }

            if mission.noEquipmentConstraint {
                NoEquipmentConstraintBadge()
            }

            controls
        }
        .padding(10)
        .themedSurface(16, tint: points == maxPoints ? .glow : nil)
        .animation(.smooth, value: points)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(mission.code) \(mission.name), \(points) points")
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        switch mission {
        case .m01:
            toggles {
                ToggleTile(
                    title: "Drone off mat",
                    subtitle: "\(p.m01DroneOffMat) pts",
                    icon: "airplane.departure",
                    isOn: $scores.m01DroneOffMat
                )
                ToggleTile(
                    title: "LiDAR map flipped",
                    subtitle: scores.m01DroneOffMat ? "+\(p.m01LidarMapFlipped) · marker in area" : "Needs drone off mat",
                    icon: "map",
                    isOn: $scores.m01LidarMapFlipped,
                    disabled: !scores.m01DroneOffMat
                )
            }
        case .m02:
            caption("Seeds off the stalk")
            CountSelector(
                value: $scores.m02SeedsOffStalk,
                max: counts.m02Seeds,
                points: p.m02Seed
            )
            .frame(height: selectorHeight)
        case .m03:
            toggles {
                ToggleTile(
                    title: "Flag down",
                    subtitle: "\(p.m03FlagDown) pts",
                    icon: "flag",
                    isOn: $scores.m03FlagDown
                )
                ToggleTile(
                    title: "Rock returned",
                    subtitle: scores.m03FlagDown ? "+\(p.m03RockReturned)" : "Needs flag down",
                    icon: "mountain.2",
                    isOn: $scores.m03RockReturned,
                    disabled: !scores.m03FlagDown
                )
            }
        case .m04:
            m04
        case .m05:
            HStack(spacing: 6) {
                SelectorItem(name: "None", subtitle: "0", value: RootExtension.none, selection: $scores.m05Roots)
                SelectorItem(name: "Partial", subtitle: "\(p.m05Partial)", value: RootExtension.partial, selection: $scores.m05Roots)
                SelectorItem(name: "Complete", subtitle: "\(p.m05Complete)", value: RootExtension.complete, selection: $scores.m05Roots)
            }
            .frame(height: selectorHeight)
        case .m06:
            toggles {
                ToggleTile(
                    title: "Ant touching nest",
                    subtitle: "Needed to score fragments",
                    icon: "ant",
                    isOn: $scores.m06AntTouchingNest
                )
            }
            caption("Leaf fragments in the nest")
            CountSelector(
                value: $scores.m06FragmentsInNest,
                max: counts.m06Fragments,
                points: p.m06Fragment,
                disabled: !scores.m06AntTouchingNest
            )
            .frame(height: selectorHeight)
        case .m07:
            toggles {
                ToggleTile(
                    title: "Mycelium extended",
                    subtitle: "\(p.m07MyceliumExtended) pts",
                    icon: "point.3.filled.connected.trianglepath.dotted",
                    isOn: $scores.m07MyceliumExtended
                )
                ToggleTile(
                    title: "Connected to opposing root",
                    subtitle: !scores.hasOpposingTeam
                        ? "No opposing team"
                        : (scores.m07MyceliumExtended ? "+\(p.m07Connected) · fully extended root" : "Needs mycelium"),
                    icon: "link",
                    isOn: $scores.m07Connected,
                    disabled: !scores.m07BonusAvailable
                )
            }
        case .m08:
            toggles {
                ToggleTile(
                    title: "Vine touching mat",
                    subtitle: "\(p.m08Vine) pts",
                    icon: "scribble",
                    isOn: $scores.m08VineTouchingMat
                )
            }
        case .m09:
            toggles {
                ToggleTile(title: "Platform raised", subtitle: "\(p.m09PlatformRaised) pts", icon: "arrow.up.square", isOn: $scores.m09PlatformRaised)
                ToggleTile(title: "Camera deployed", subtitle: "\(p.m09CameraDeployed) pts", icon: "camera", isOn: $scores.m09CameraDeployed)
                ToggleTile(title: "Seed off tree", subtitle: "\(p.m09SeedOffTree) pts", icon: "tree", isOn: $scores.m09SeedOffTree)
            }
        case .m10:
            toggles {
                ToggleTile(title: "Spider habitat", subtitle: "\(p.m10Spider) · in start position", icon: "ladybug", isOn: $scores.m10SpiderInStart)
                ToggleTile(title: "Snail habitat", subtitle: "\(p.m10Snail) · in start position", icon: "tortoise", isOn: $scores.m10SnailInStart)
            }
        case .m11:
            toggles {
                ToggleTile(title: "Root cover down", subtitle: "\(p.m11RootCover) pts", icon: "rectangle.bottomhalf.filled", isOn: $scores.m11RootCoverDown)
            }
        case .m12:
            toggles {
                ToggleTile(title: "Cane raised", subtitle: "\(p.m12CaneRaised) pts", icon: "arrow.up", isOn: $scores.m12CaneRaised)
                ToggleTile(title: "Support tie around post", subtitle: "\(p.m12SupportTie) pts", icon: "lasso", isOn: $scores.m12SupportTieAroundPost)
            }
        case .m13:
            toggles {
                ToggleTile(
                    title: "Species on platform, young trees raised",
                    subtitle: "\(p.m13Keystone) pts",
                    icon: "hare",
                    isOn: $scores.m13Keystone
                )
            }
        case .m14:
            caption("Seeds in the station")
            CountSelector(
                value: $scores.m14SeedsInStation,
                max: counts.m14Seeds,
                points: p.m14SeedInStation
            )
            .frame(height: selectorHeight)
            caption("Of those, also touching the mat")
            HStack(spacing: 6) {
                ForEach(0...counts.m14Seeds, id: \.self) { count in
                    SelectorItem(
                        name: "\(count)",
                        subtitle: "+\(count * p.m14SeedTouchingMat)",
                        value: count,
                        selection: $scores.m14SeedsTouchingMat,
                        disabled: count > scores.m14SeedsInStation
                    )
                }
            }
            .frame(height: selectorHeight)
        case .m15:
            m15
        }
    }

    private var m04: some View {
        let voided = scores.m04Voided

        return VStack(alignment: .leading, spacing: 10) {
            caption("Leaves removed")
            HStack(spacing: 6) {
                SelectorItem(name: "0", subtitle: "0", value: 0, selection: $scores.m04LeavesRemoved)
                SelectorItem(name: "1", subtitle: "\(p.m04OneLeaf)", value: 1, selection: $scores.m04LeavesRemoved)
                SelectorItem(
                    name: "2",
                    subtitle: scores.m04BonusAvailable
                        ? "\(p.m04OneLeaf + p.m04SecondLeaf)" : "\(p.m04OneLeaf)",
                    value: 2,
                    selection: $scores.m04LeavesRemoved
                )
            }
            .frame(height: selectorHeight)
            .grayscale(voided ? 1 : 0)
            .opacity(voided ? 0.4 : 1)

            caption("Katydid outside the leaf habitat")
            toggles {
                ToggleTile(
                    title: "During the match",
                    subtitle: "No +\(p.m04SecondLeaf)",
                    icon: "arrow.up.right",
                    isOn: $scores.m04KatydidLeftHabitat
                )
                ToggleTile(
                    title: "At the end",
                    subtitle: "Mission scores 0",
                    icon: "xmark.circle",
                    isOn: $scores.m04KatydidOutsideAtEnd
                )
            }

            if voided {
                Label("0 — katydid outside the habitat at the end", systemImage: "xmark.octagon.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            } else if scores.m04LeavesRemoved == 2 && !scores.m04BonusAvailable {
                Label("The +\(p.m04SecondLeaf) needs the katydid to stay in the habitat", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var m15: some View {
        let needed = scores.m15Dock?.bonusAction

        return VStack(alignment: .leading, spacing: 10) {
            caption("Dock")
            HStack(spacing: 6) {
                ForEach(Dock.allCases, id: \.self) { dock in
                    SelectorItem(
                        name: dock.rawValue,
                        subtitle: "→ \(dock.bonusAction.rawValue)",
                        value: Optional(dock),
                        selection: $scores.m15Dock
                    )
                }
            }
            .frame(height: selectorHeight)

            toggles {
                ToggleTile(
                    title: "Canopy",
                    subtitle: subtitle(p.m15Canopy, bonus: needed == .canopy),
                    icon: "umbrella",
                    isOn: $scores.m15Canopy,
                    highlighted: needed == .canopy
                )
                ToggleTile(
                    title: "Skylight",
                    subtitle: subtitle(p.m15Skylight, bonus: needed == .skylight),
                    icon: "sun.max",
                    isOn: $scores.m15Skylight,
                    highlighted: needed == .skylight
                )
                ToggleTile(
                    title: "Hatch",
                    subtitle: subtitle(p.m15Hatch, bonus: needed == .hatch),
                    icon: "door.left.hand.open",
                    isOn: $scores.m15Hatch,
                    highlighted: needed == .hatch
                )
            }

            if needed == nil {
                Label("Pick the dock to score the +\(p.m15DockBonus) environmental bonus", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Helpers

    private func subtitle(_ points: Int, bonus: Bool) -> String {
        bonus ? "\(points) +\(p.m15DockBonus) bonus" : "\(points) pts"
    }

    private func toggles<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 6) {
            content()
        }
        .frame(height: toggleHeight)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}
