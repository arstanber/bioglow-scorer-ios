//
//  ScoringLog.swift
//  BIOGLOW
//
//  Undo history, the match log and the point-by-point score breakdown.
//

import Foundation

struct ScoreChange: Hashable {
    /// Identifies the field that changed, so rapid edits to it can be merged.
    let key: String
    let text: String
}

/// A saved line in the match log.
struct MatchLogEntry: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    /// The match clock when the change was made, e.g. "2:14".
    var clock: String?
    var text: String
}

/// An undoable change while scoring.
struct ScoringEvent: Identifiable {
    let id = UUID()
    var date: Date
    var clock: String?
    var changes: [ScoreChange]
    /// The scores before this event.
    let previous: BioGlowScores

    var entry: MatchLogEntry {
        MatchLogEntry(
            date: date,
            clock: clock,
            text: changes.map(\.text).joined(separator: " · ")
        )
    }
}

extension BioGlowScores {
    /// Human-readable differences from `old`.
    func changes(from old: BioGlowScores) -> [ScoreChange] {
        var changes: [ScoreChange] = []

        func toggle(_ key: String, _ label: String, _ old: Bool, _ new: Bool) {
            guard old != new else { return }
            changes.append(ScoreChange(key: key, text: "\(label) \(new ? "✓" : "✗")"))
        }

        func counter(_ key: String, _ label: String, _ old: Int, _ new: Int) {
            guard old != new else { return }
            changes.append(ScoreChange(key: key, text: "\(label) \(old) → \(new)"))
        }

        func choice(_ key: String, _ label: String, _ old: String, _ new: String) {
            guard old != new else { return }
            changes.append(ScoreChange(key: key, text: "\(label): \(new)"))
        }

        toggle("inspection", "Equipment inspection", old.inspectionPassed, inspectionPassed)

        if old.precisionTokens != precisionTokens {
            let text =
                precisionTokens == old.precisionTokens - 1
                ? "Token lost (\(precisionTokens) left)"
                : "Precision tokens \(old.precisionTokens) → \(precisionTokens)"
            changes.append(ScoreChange(key: "tokens", text: text))
        }

        toggle("opposingTeam", "Opposing team", old.hasOpposingTeam, hasOpposingTeam)
        choice("gp", "GP", "\(old.gp.rawValue) \(old.gp.title)", "\(gp.rawValue) \(gp.title)")

        toggle("m01.drone", "M01 drone off mat", old.m01DroneOffMat, m01DroneOffMat)
        toggle("m01.lidar", "M01 LiDAR map", old.m01LidarMapFlipped, m01LidarMapFlipped)
        counter("m02.seeds", "M02 seeds", old.m02SeedsOffStalk, m02SeedsOffStalk)
        toggle("m03.flag", "M03 flag down", old.m03FlagDown, m03FlagDown)
        toggle("m03.rock", "M03 rock returned", old.m03RockReturned, m03RockReturned)
        counter("m04.leaves", "M04 leaves", old.m04LeavesRemoved, m04LeavesRemoved)
        toggle("m04.katydidLeft", "M04 katydid left habitat", old.m04KatydidLeftHabitat, m04KatydidLeftHabitat)
        toggle("m04.katydidEnd", "M04 katydid outside at end", old.m04KatydidOutsideAtEnd, m04KatydidOutsideAtEnd)
        choice("m05.roots", "M05 roots", old.m05Roots.rawValue, m05Roots.rawValue)
        toggle("m06.ant", "M06 ant touching nest", old.m06AntTouchingNest, m06AntTouchingNest)
        counter("m06.fragments", "M06 fragments", old.m06FragmentsInNest, m06FragmentsInNest)
        toggle("m07.mycelium", "M07 mycelium extended", old.m07MyceliumExtended, m07MyceliumExtended)
        toggle("m07.connected", "M07 connected to opposing root", old.m07Connected, m07Connected)
        toggle("m08.vine", "M08 vine touching mat", old.m08VineTouchingMat, m08VineTouchingMat)
        toggle("m09.platform", "M09 platform raised", old.m09PlatformRaised, m09PlatformRaised)
        toggle("m09.camera", "M09 camera deployed", old.m09CameraDeployed, m09CameraDeployed)
        toggle("m09.seed", "M09 seed off tree", old.m09SeedOffTree, m09SeedOffTree)
        toggle("m10.spider", "M10 spider habitat", old.m10SpiderInStart, m10SpiderInStart)
        toggle("m10.snail", "M10 snail habitat", old.m10SnailInStart, m10SnailInStart)
        toggle("m11.cover", "M11 root cover down", old.m11RootCoverDown, m11RootCoverDown)
        toggle("m12.cane", "M12 cane raised", old.m12CaneRaised, m12CaneRaised)
        toggle("m12.tie", "M12 support tie", old.m12SupportTieAroundPost, m12SupportTieAroundPost)
        toggle("m13.keystone", "M13 keystone species", old.m13Keystone, m13Keystone)
        counter("m14.station", "M14 seeds in station", old.m14SeedsInStation, m14SeedsInStation)
        counter("m14.mat", "M14 seeds touching mat", old.m14SeedsTouchingMat, m14SeedsTouchingMat)
        choice("m15.dock", "M15 dock", old.m15Dock?.rawValue ?? "None", m15Dock?.rawValue ?? "None")
        toggle("m15.canopy", "M15 canopy", old.m15Canopy, m15Canopy)
        toggle("m15.skylight", "M15 skylight", old.m15Skylight, m15Skylight)
        toggle("m15.hatch", "M15 hatch", old.m15Hatch, m15Hatch)

        return changes
    }

    struct BreakdownLine: Hashable, Identifiable {
        let label: String
        let detail: String
        let points: Int
        /// Missions without equipment constraint get a reminder badge.
        var noEquipmentConstraint: Bool = false

        var id: String { label }
    }

    /// What was scored for `mission`, e.g. "Drone off mat · LiDAR map".
    func detail(for mission: Mission) -> String {
        var parts: [String] = []

        func add(_ condition: Bool, _ text: String) {
            if condition { parts.append(text) }
        }

        switch mission {
        case .m01:
            add(m01DroneOffMat, "Drone off mat")
            add(m01DroneOffMat && m01LidarMapFlipped, "LiDAR map")
        case .m02:
            add(m02SeedsOffStalk > 0, "\(m02SeedsOffStalk) of \(BioGlowPoints.counts.m02Seeds) seeds")
        case .m03:
            add(m03FlagDown, "Flag down")
            add(m03FlagDown && m03RockReturned, "Rock returned")
        case .m04:
            if m04Voided && m04LeavesRemoved > 0 {
                parts.append("Katydid outside the habitat at the end")
            } else {
                add(m04LeavesRemoved > 0, "\(m04LeavesRemoved) leaf\(m04LeavesRemoved == 1 ? "" : "ves") removed")
                add(m04LeavesRemoved >= 2 && !m04BonusAvailable, "katydid left the habitat")
            }
        case .m05:
            add(m05Roots != .none, "\(m05Roots.rawValue) roots")
        case .m06:
            add(m06AntTouchingNest, "\(m06FragmentsInNest) of \(BioGlowPoints.counts.m06Fragments) fragments")
        case .m07:
            add(m07MyceliumExtended, "Mycelium extended")
            add(m07BonusAvailable && m07Connected, "connected")
        case .m08:
            add(m08VineTouchingMat, "Vine touching mat")
        case .m09:
            add(m09PlatformRaised, "Platform")
            add(m09CameraDeployed, "Camera")
            add(m09SeedOffTree, "Seed")
        case .m10:
            add(m10SpiderInStart, "Spider")
            add(m10SnailInStart, "Snail")
        case .m11:
            add(m11RootCoverDown, "Root cover down")
        case .m12:
            add(m12CaneRaised, "Cane raised")
            add(m12SupportTieAroundPost, "Support tie")
        case .m13:
            add(m13Keystone, "Species on platform")
        case .m14:
            add(m14SeedsInStation > 0, "\(m14SeedsInStation) in station")
            add(m14SeedsTouchingMat > 0, "\(m14SeedsTouchingMat) touching mat")
        case .m15:
            add(m15Canopy, "Canopy")
            add(m15Skylight, "Skylight")
            add(m15Hatch, "Hatch")
            if let dock = m15Dock, isDone(dock.bonusAction) {
                parts.append("\(dock.rawValue) bonus")
            }
        }

        return parts.isEmpty ? "Not scored" : parts.joined(separator: " · ")
    }

    /// Every source of points, in rulebook order. Gracious Professionalism is listed separately.
    func breakdown() -> [BreakdownLine] {
        var lines = [
            BreakdownLine(
                label: "Equipment inspection",
                detail: inspectionPassed ? "Passed" : "Not passed",
                points: inspectionPoints
            ),
            BreakdownLine(
                label: "Precision tokens",
                detail: "\(precisionTokens) left",
                points: tokenPoints
            ),
        ]

        for mission in Mission.allCases {
            lines.append(
                BreakdownLine(
                    label: "\(mission.code) \(mission.name)",
                    detail: detail(for: mission),
                    points: points(for: mission),
                    noEquipmentConstraint: mission.noEquipmentConstraint
                )
            )
        }

        return lines
    }
}
