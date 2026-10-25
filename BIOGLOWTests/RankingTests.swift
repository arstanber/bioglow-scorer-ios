//
//  RankingTests.swift
//  BIOGLOWTests
//

import Foundation
import Testing
@testable import BIOGLOW

@Suite("Best-of-3 rankings")
struct RankingTests {
    private func entry(
        _ team: String?,
        _ round: MatchRound,
        _ total: Int,
        at offset: TimeInterval = 0
    ) -> RankingEntry {
        RankingEntry(
            teamNumber: team,
            round: round,
            total: total,
            timestamp: Date(timeIntervalSince1970: 1_000_000 + offset)
        )
    }

    @Test func ranksByBestScore() {
        let records = TeamRecord.records(from: [
            entry("100", .round1, 200),
            entry("200", .round1, 310),
            entry("300", .round1, 150),
            entry("300", .round2, 250),
        ])
        #expect(records.map(\.teamNumber) == ["200", "300", "100"])
        #expect(records[1].best == 250)
        #expect(records[1].second == 150)
        #expect(records[1].third == 0)
    }

    @Test func tiebreaksOnSecondThenThird() {
        let records = TeamRecord.records(from: [
            entry("A", .round1, 300), entry("A", .round2, 200), entry("A", .round3, 100),
            entry("B", .round1, 300), entry("B", .round2, 250), entry("B", .round3, 50),
            entry("C", .round1, 300), entry("C", .round2, 200), entry("C", .round3, 150),
        ])
        #expect(records.map(\.teamNumber) == ["B", "C", "A"])
    }

    @Test func allThreeTiedIsDetected() {
        let records = TeamRecord.records(from: [
            entry("12", .round1, 300), entry("12", .round2, 200), entry("12", .round3, 100),
            entry("7", .round1, 100), entry("7", .round2, 300), entry("7", .round3, 200),
        ])
        #expect(records[0].isTied(with: records[1]))
        // Fully tied teams fall back to team number order.
        #expect(records.map(\.teamNumber) == ["7", "12"])
    }

    @Test func practiceAndTeamlessMatchesAreIgnored() {
        let records = TeamRecord.records(from: [
            entry("100", .practice, 500),
            entry("100", .round1, 120),
            entry(nil, .round1, 400),
            entry("  ", .round2, 400),
            entry("200", .practice, 300),
        ])
        #expect(records.map(\.teamNumber) == ["100"])
        #expect(records[0].best == 120)
        #expect(records[0].officialScores == [120])
    }

    @Test func duplicateRoundsWarnAndUseTheLatest() throws {
        let records = TeamRecord.records(from: [
            entry("100", .round1, 400, at: 0),
            entry("100", .round1, 150, at: 60),
            entry("100", .round2, 200, at: 120),
        ])
        let record = try #require(records.first)
        #expect(record.duplicateRounds == [.round1])
        #expect(record.officialScores == [200, 150])
    }
}
