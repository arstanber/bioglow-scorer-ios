//
//  BioGlowScores.swift
//  BIOGLOW
//
//  Scoring model for the BIOGLOW robot game, Robot Game Rulebook p. 8–12 and 18.
//

import Foundation

/// Point values read from `GameRules.current` so Challenge Updates can change them.
enum BioGlowPoints {
    static var points: GameRules.Points { GameRules.current.points }
    static var counts: GameRules.Counts { GameRules.current.counts }
    static var tokenPoints: [Int] { GameRules.current.tokenPoints }
}

enum Mission: Int, CaseIterable, Codable, Hashable, Identifiable {
    case m01 = 1, m02, m03, m04, m05, m06, m07, m08, m09, m10, m11, m12, m13, m14, m15

    var id: Int { rawValue }

    /// "M01"
    var code: String { String(format: "M%02d", rawValue) }

    var name: String {
        switch self {
        case .m01: "Drone Survey"
        case .m02: "Exploding Seeds"
        case .m03: "Flip the Rock"
        case .m04: "Lucky Leaves"
        case .m05: "Reaching Roots"
        case .m06: "Leafcutter Frenzy"
        case .m07: "Humongous Fungus"
        case .m08: "Tangled"
        case .m09: "Research Platform"
        case .m10: "Fragile Microhabitats"
        case .m11: "Window to the Past"
        case .m12: "Forest Elder"
        case .m13: "Keystone Species"
        case .m14: "Seeds of Renewal"
        case .m15: "Biocentric Architecture"
        }
    }

    var icon: String {
        switch self {
        case .m01: "airplane"
        case .m02: "sparkles"
        case .m03: "flag.fill"
        case .m04: "leaf.fill"
        case .m05: "arrow.down.to.line"
        case .m06: "ant.fill"
        case .m07: "point.3.connected.trianglepath.dotted"
        case .m08: "scribble.variable"
        case .m09: "camera.fill"
        case .m10: "ladybug.fill"
        case .m11: "window.vertical.closed"
        case .m12: "tree.fill"
        case .m13: "hare.fill"
        case .m14: "circle.grid.cross.fill"
        case .m15: "building.2.fill"
        }
    }

    /// Missions where equipment may be left behind without breaking the equipment constraint.
    var noEquipmentConstraint: Bool {
        [.m01, .m04, .m05, .m07, .m15].contains(self)
    }

    var maxPoints: Int {
        var scores = BioGlowScores.completed
        scores.hasOpposingTeam = true
        return scores.points(for: self)
    }
}

enum RootExtension: String, Codable, Hashable, CaseIterable {
    case none = "None"
    case partial = "Partial"
    case complete = "Complete"
}

enum Dock: String, Codable, Hashable, CaseIterable {
    case mine = "Mine"
    case city = "City"
    case farm = "Farm"

    /// The M15 action that earns the environmental bonus at this dock.
    var bonusAction: BiocentricAction {
        switch self {
        case .mine: .canopy
        case .city: .skylight
        case .farm: .hatch
        }
    }
}

enum BiocentricAction: String, Codable, Hashable, CaseIterable {
    case canopy = "Canopy"
    case skylight = "Skylight"
    case hatch = "Hatch"
}

/// Gracious Professionalism®. Recorded with the match but not part of the robot game score.
enum GraciousProfessionalism: Int, Codable, Hashable, CaseIterable {
    case developing = 2
    case accomplished = 3
    case exceeds = 4

    var title: String {
        switch self {
        case .developing: "Developing"
        case .accomplished: "Accomplished"
        case .exceeds: "Exceeds"
        }
    }
}

struct BioGlowScores: Codable, Hashable {
    // MARK: Match

    /// All equipment fits in one launch area and under 305 mm.
    var inspectionPassed: Bool = false
    var precisionTokens: Int = GameRules.maxTokens {
        didSet { precisionTokens = min(GameRules.maxTokens, max(0, precisionTokens)) }
    }
    /// Off for remote play, where no team is across the table for the M07 bonus.
    var hasOpposingTeam: Bool = true {
        didSet { if !hasOpposingTeam { m07Connected = false } }
    }
    var gp: GraciousProfessionalism = .accomplished

    // MARK: Missions

    var m01DroneOffMat: Bool = false {
        didSet { if !m01DroneOffMat { m01LidarMapFlipped = false } }
    }
    /// LiDAR map flipped with its marker in the survey area.
    var m01LidarMapFlipped: Bool = false

    var m02SeedsOffStalk: Int = 0 {
        didSet { m02SeedsOffStalk = Self.clamp(m02SeedsOffStalk, BioGlowPoints.counts.m02Seeds) }
    }

    var m03FlagDown: Bool = false {
        didSet { if !m03FlagDown { m03RockReturned = false } }
    }
    var m03RockReturned: Bool = false

    var m04LeavesRemoved: Int = 0 {
        didSet { m04LeavesRemoved = Self.clamp(m04LeavesRemoved, 2) }
    }
    /// Challenge Update 01 (September 2nd, 2026): the leaves are randomized and the
    /// katydid's starting placement isn't told to the team, so only two things matter.
    /// Leaving the leaf habitat at any point during the match costs the bonus.
    var m04KatydidLeftHabitat: Bool = false {
        didSet { if !m04KatydidLeftHabitat { m04KatydidOutsideAtEnd = false } }
    }
    /// Completely outside the leaf habitat at the end of the match: the mission scores nothing.
    var m04KatydidOutsideAtEnd: Bool = false {
        didSet { if m04KatydidOutsideAtEnd { m04KatydidLeftHabitat = true } }
    }

    var m05Roots: RootExtension = .none

    var m06AntTouchingNest: Bool = false {
        didSet { if !m06AntTouchingNest { m06FragmentsInNest = 0 } }
    }
    var m06FragmentsInNest: Int = 0 {
        didSet { m06FragmentsInNest = Self.clamp(m06FragmentsInNest, BioGlowPoints.counts.m06Fragments) }
    }

    var m07MyceliumExtended: Bool = false {
        didSet { if !m07MyceliumExtended { m07Connected = false } }
    }
    /// Connected to the opposing team's fully extended root.
    var m07Connected: Bool = false

    var m08VineTouchingMat: Bool = false

    var m09PlatformRaised: Bool = false
    var m09CameraDeployed: Bool = false
    var m09SeedOffTree: Bool = false

    var m10SpiderInStart: Bool = false
    var m10SnailInStart: Bool = false

    var m11RootCoverDown: Bool = false

    var m12CaneRaised: Bool = false
    var m12SupportTieAroundPost: Bool = false

    /// Species on the platform and young trees raised.
    var m13Keystone: Bool = false

    var m14SeedsInStation: Int = 0 {
        didSet {
            m14SeedsInStation = Self.clamp(m14SeedsInStation, BioGlowPoints.counts.m14Seeds)
            m14SeedsTouchingMat = min(m14SeedsTouchingMat, m14SeedsInStation)
        }
    }
    /// Seeds in the station that also touch the mat.
    var m14SeedsTouchingMat: Int = 0 {
        didSet { m14SeedsTouchingMat = Self.clamp(m14SeedsTouchingMat, m14SeedsInStation) }
    }

    var m15Dock: Dock? = nil
    var m15Canopy: Bool = false
    var m15Skylight: Bool = false
    var m15Hatch: Bool = false

    private static func clamp(_ value: Int, _ upper: Int) -> Int {
        min(upper, max(0, value))
    }

    // MARK: Actions

    /// An interruption costs one precision token.
    mutating func interrupt() {
        precisionTokens -= 1
    }

    func isDone(_ action: BiocentricAction) -> Bool {
        switch action {
        case .canopy: m15Canopy
        case .skylight: m15Skylight
        case .hatch: m15Hatch
        }
    }

    // MARK: Points

    var inspectionPoints: Int {
        inspectionPassed ? BioGlowPoints.points.inspection : 0
    }

    var tokenPoints: Int {
        let table = BioGlowPoints.tokenPoints
        return table[min(table.count - 1, max(0, precisionTokens))]
    }

    /// M07's bonus needs a team across the table.
    var m07BonusAvailable: Bool {
        hasOpposingTeam && m07MyceliumExtended
    }

    /// M04 scores nothing when the katydid ends the match outside the leaf habitat.
    var m04Voided: Bool {
        m04KatydidOutsideAtEnd
    }

    /// The second leaf only scores while the katydid has stayed in the leaf habitat.
    var m04BonusAvailable: Bool {
        !m04KatydidLeftHabitat
    }

    func points(for mission: Mission) -> Int {
        let p = BioGlowPoints.points

        func value(_ condition: Bool, _ points: Int) -> Int {
            condition ? points : 0
        }

        switch mission {
        case .m01:
            return value(m01DroneOffMat, p.m01DroneOffMat)
                + value(m01DroneOffMat && m01LidarMapFlipped, p.m01LidarMapFlipped)
        case .m02:
            return m02SeedsOffStalk * p.m02Seed
        case .m03:
            return value(m03FlagDown, p.m03FlagDown)
                + value(m03FlagDown && m03RockReturned, p.m03RockReturned)
        case .m04:
            guard !m04Voided else { return 0 }
            return value(m04LeavesRemoved >= 1, p.m04OneLeaf)
                + value(m04LeavesRemoved >= 2 && m04BonusAvailable, p.m04SecondLeaf)
        case .m05:
            switch m05Roots {
            case .none: return 0
            case .partial: return p.m05Partial
            case .complete: return p.m05Complete
            }
        case .m06:
            return m06AntTouchingNest ? m06FragmentsInNest * p.m06Fragment : 0
        case .m07:
            return value(m07MyceliumExtended, p.m07MyceliumExtended)
                + value(m07BonusAvailable && m07Connected, p.m07Connected)
        case .m08:
            return value(m08VineTouchingMat, p.m08Vine)
        case .m09:
            return value(m09PlatformRaised, p.m09PlatformRaised)
                + value(m09CameraDeployed, p.m09CameraDeployed)
                + value(m09SeedOffTree, p.m09SeedOffTree)
        case .m10:
            return value(m10SpiderInStart, p.m10Spider)
                + value(m10SnailInStart, p.m10Snail)
        case .m11:
            return value(m11RootCoverDown, p.m11RootCover)
        case .m12:
            return value(m12CaneRaised, p.m12CaneRaised)
                + value(m12SupportTieAroundPost, p.m12SupportTie)
        case .m13:
            return value(m13Keystone, p.m13Keystone)
        case .m14:
            let touching = min(m14SeedsTouchingMat, m14SeedsInStation)
            return m14SeedsInStation * p.m14SeedInStation
                + touching * p.m14SeedTouchingMat
        case .m15:
            let bonus = m15Dock.map { isDone($0.bonusAction) } ?? false
            return value(m15Canopy, p.m15Canopy)
                + value(m15Skylight, p.m15Skylight)
                + value(m15Hatch, p.m15Hatch)
                + value(bonus, p.m15DockBonus)
        }
    }

    var missionPoints: Int {
        Mission.allCases.map(points(for:)).reduce(0, +)
    }

    /// The robot game score. Gracious Professionalism is not included.
    var total: Int {
        inspectionPoints + tokenPoints + missionPoints
    }

    /// Whether anything was scored, ignoring match settings.
    var isBlank: Bool {
        var blank = BioGlowScores()
        blank.hasOpposingTeam = hasOpposingTeam
        blank.gp = gp
        return self == blank
    }

    /// Every condition met, for the maximum score.
    static var completed: BioGlowScores {
        let counts = BioGlowPoints.counts
        var scores = BioGlowScores()
        scores.inspectionPassed = true
        scores.m01DroneOffMat = true
        scores.m01LidarMapFlipped = true
        scores.m02SeedsOffStalk = counts.m02Seeds
        scores.m03FlagDown = true
        scores.m03RockReturned = true
        scores.m04LeavesRemoved = 2
        scores.m05Roots = .complete
        scores.m06AntTouchingNest = true
        scores.m06FragmentsInNest = counts.m06Fragments
        scores.m07MyceliumExtended = true
        scores.m07Connected = true
        scores.m08VineTouchingMat = true
        scores.m09PlatformRaised = true
        scores.m09CameraDeployed = true
        scores.m09SeedOffTree = true
        scores.m10SpiderInStart = true
        scores.m10SnailInStart = true
        scores.m11RootCoverDown = true
        scores.m12CaneRaised = true
        scores.m12SupportTieAroundPost = true
        scores.m13Keystone = true
        scores.m14SeedsInStation = counts.m14Seeds
        scores.m14SeedsTouchingMat = counts.m14Seeds
        scores.m15Dock = .mine
        scores.m15Canopy = true
        scores.m15Skylight = true
        scores.m15Hatch = true
        return scores
    }
}
