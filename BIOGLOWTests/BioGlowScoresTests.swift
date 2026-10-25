//
//  BioGlowScoresTests.swift
//  BIOGLOWTests
//

import Testing
@testable import BIOGLOW

@Suite("BIOGLOW scoring")
struct BioGlowScoresTests {
    @Test func completedFieldTotals510() {
        #expect(BioGlowScores.completed.total == 510)
    }

    @Test func emptyFieldWithAllTokensAndNoInspectionIs50() {
        let scores = BioGlowScores()
        #expect(scores.inspectionPassed == false)
        #expect(scores.precisionTokens == 6)
        #expect(scores.missionPoints == 0)
        #expect(scores.total == 50)
        #expect(scores.isBlank)
    }

    @Test func inspectionAdds20() {
        var scores = BioGlowScores()
        scores.inspectionPassed = true
        #expect(scores.total == 70)
    }

    @Test(arguments: [(0, 0), (1, 10), (2, 15), (3, 25), (4, 35), (5, 50), (6, 50)])
    func tokenTable(tokens: Int, points: Int) {
        var scores = BioGlowScores()
        scores.precisionTokens = tokens
        #expect(scores.tokenPoints == points)
    }

    @Test func interruptionsStopAtZero() {
        var scores = BioGlowScores()
        for expected in stride(from: 5, through: 0, by: -1) {
            scores.interrupt()
            #expect(scores.precisionTokens == expected)
        }
        scores.interrupt()
        #expect(scores.precisionTokens == 0)
        #expect(scores.tokenPoints == 0)

        scores.precisionTokens = 9
        #expect(scores.precisionTokens == 6)
    }

    @Test func katydidLeavingTheHabitatCostsTheM04Bonus() {
        var scores = BioGlowScores()
        scores.m04LeavesRemoved = 2
        #expect(scores.points(for: .m04) == 30)

        // Outside the habitat at any point during the match: base only.
        scores.m04KatydidLeftHabitat = true
        #expect(scores.m04BonusAvailable == false)
        #expect(scores.points(for: .m04) == 10)

        // Still outside at the end: the whole mission scores nothing.
        scores.m04KatydidOutsideAtEnd = true
        #expect(scores.points(for: .m04) == 0)

        scores.m04LeavesRemoved = 1
        #expect(scores.points(for: .m04) == 0)
    }

    @Test func katydidFlagsStayConsistent() {
        var scores = BioGlowScores()

        // Outside at the end implies it left the habitat.
        scores.m04KatydidOutsideAtEnd = true
        #expect(scores.m04KatydidLeftHabitat)

        // Taking back the match-long flag clears the end-of-match one.
        scores.m04KatydidLeftHabitat = false
        #expect(scores.m04KatydidOutsideAtEnd == false)
        #expect(scores.m04Voided == false)

        scores.m04LeavesRemoved = 2
        #expect(scores.points(for: .m04) == 30)
    }

    @Test func m05IsExclusive() {
        var scores = BioGlowScores()
        scores.m05Roots = .partial
        #expect(scores.points(for: .m05) == 10)
        scores.m05Roots = .complete
        #expect(scores.points(for: .m05) == 20)
        scores.m05Roots = .none
        #expect(scores.points(for: .m05) == 0)
    }

    @Test func bonusesNeedTheirBase() {
        var scores = BioGlowScores()

        scores.m01LidarMapFlipped = true
        #expect(scores.points(for: .m01) == 0)
        scores.m01DroneOffMat = true
        scores.m01LidarMapFlipped = true
        #expect(scores.points(for: .m01) == 30)
        scores.m01DroneOffMat = false
        #expect(scores.m01LidarMapFlipped == false)
        #expect(scores.points(for: .m01) == 0)

        scores.m03RockReturned = true
        #expect(scores.points(for: .m03) == 0)
        scores.m03FlagDown = true
        scores.m03RockReturned = true
        #expect(scores.points(for: .m03) == 30)
        scores.m03FlagDown = false
        #expect(scores.m03RockReturned == false)

        scores.m06FragmentsInNest = 3
        #expect(scores.points(for: .m06) == 0)
        scores.m06AntTouchingNest = true
        scores.m06FragmentsInNest = 3
        #expect(scores.points(for: .m06) == 30)
        scores.m06AntTouchingNest = false
        #expect(scores.m06FragmentsInNest == 0)

        scores.m07Connected = true
        #expect(scores.points(for: .m07) == 0)
        scores.m07MyceliumExtended = true
        scores.m07Connected = true
        #expect(scores.points(for: .m07) == 30)
        scores.m07MyceliumExtended = false
        #expect(scores.m07Connected == false)
    }

    @Test func m07BonusNeedsAnOpposingTeam() {
        var scores = BioGlowScores()
        scores.m07MyceliumExtended = true
        scores.m07Connected = true
        #expect(scores.points(for: .m07) == 30)

        scores.hasOpposingTeam = false
        #expect(scores.m07Connected == false)
        #expect(scores.m07BonusAvailable == false)
        #expect(scores.points(for: .m07) == 20)

        // Even if decoded data carries the bonus, it doesn't score without a team.
        scores.m07Connected = true
        #expect(scores.points(for: .m07) == 20)
    }

    @Test func m14TouchingNeverExceedsInStation() {
        var scores = BioGlowScores()
        scores.m14SeedsTouchingMat = 2
        #expect(scores.m14SeedsTouchingMat == 0)

        scores.m14SeedsInStation = 3
        scores.m14SeedsTouchingMat = 3
        #expect(scores.points(for: .m14) == 30)

        scores.m14SeedsInStation = 1
        #expect(scores.m14SeedsTouchingMat == 1)
        #expect(scores.points(for: .m14) == 10)

        scores.m14SeedsInStation = 10
        #expect(scores.m14SeedsInStation == 3)
    }

    @Test(arguments: Dock.allCases)
    func m15BonusFollowsTheDock(dock: Dock) {
        var scores = BioGlowScores()
        scores.m15Canopy = true
        #expect(scores.points(for: .m15) == 10)

        scores.m15Dock = dock
        #expect(scores.points(for: .m15) == (dock == .mine ? 20 : 10))

        scores.m15Canopy = false
        switch dock {
        case .mine: scores.m15Canopy = true
        case .city: scores.m15Skylight = true
        case .farm: scores.m15Hatch = true
        }
        #expect(scores.points(for: .m15) == 20)
    }

    @Test func gracefulProfessionalismIsNotInTheTotal() {
        var scores = BioGlowScores.completed
        for gp in GraciousProfessionalism.allCases {
            scores.gp = gp
            #expect(scores.total == 510)
        }
    }

    @Test func missionMaximums() {
        let expected: [Mission: Int] = [
            .m01: 30, .m02: 30, .m03: 30, .m04: 30, .m05: 20,
            .m06: 40, .m07: 30, .m08: 30, .m09: 30, .m10: 20,
            .m11: 20, .m12: 30, .m13: 30, .m14: 30, .m15: 40,
        ]
        for mission in Mission.allCases {
            #expect(mission.maxPoints == expected[mission], "\(mission.code)")
        }
    }

    @Test func changesDescribeTokenLoss() {
        let before = BioGlowScores()
        var after = before
        after.interrupt()
        after.precisionTokens -= 1
        #expect(after.changes(from: before).map(\.text) == ["Precision tokens 6 → 4"])

        var single = before
        single.interrupt()
        #expect(single.changes(from: before).map(\.text) == ["Token lost (5 left)"])

        var fragments = before
        fragments.m06AntTouchingNest = true
        fragments.m06FragmentsInNest = 2
        var more = fragments
        more.m06FragmentsInNest = 3
        #expect(more.changes(from: fragments).map(\.text) == ["M06 fragments 2 → 3"])
    }
}
