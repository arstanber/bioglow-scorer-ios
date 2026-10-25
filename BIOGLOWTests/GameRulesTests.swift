//
//  GameRulesTests.swift
//  BIOGLOWTests
//

import Foundation
import Testing
@testable import BIOGLOW

@Suite("Game rules data")
struct GameRulesTests {
    /// `config/game-rules.json` in the repository, which the app downloads.
    private var publishedURL: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "config/game-rules.json")
    }

    private func bundledData() throws -> Data {
        let url = try #require(Bundle.main.url(forResource: "game-rules", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test func bundledFileDecodesAndValidates() throws {
        var rules = try GameRules.decode(bundledData())
        // The fallback in code carries no notes.
        rules.notes = nil
        #expect(rules == GameRules.rulebook)
        #expect(rules.matchSeconds == 150)
        #expect(rules.tokenPoints.count == 7)
    }

    @Test func publishedFileMatchesBundledFile() throws {
        let published = try GameRules.decode(Data(contentsOf: publishedURL))
        let bundled = try GameRules.decode(bundledData())
        #expect(published == bundled)
    }

    @Test func rejectsUnknownSchema() {
        var rules = GameRules.rulebook
        rules.schema = 2
        #expect(throws: GameRules.ValidationError.unsupportedSchema(2)) {
            try rules.validate()
        }
    }

    @Test func rejectsWrongTokenCount() {
        var rules = GameRules.rulebook
        rules.tokenPoints = [0, 10, 15, 25, 35, 50]
        #expect(throws: GameRules.ValidationError.outOfRange("tokenPoints")) {
            try rules.validate()
        }
    }

    @Test func rejectsDecreasingTokens() {
        var rules = GameRules.rulebook
        rules.tokenPoints = [0, 10, 15, 25, 35, 50, 40]
        #expect(throws: GameRules.ValidationError.outOfRange("tokenPoints")) {
            try rules.validate()
        }
    }

    @Test func rejectsOutOfRangePoints() {
        var rules = GameRules.rulebook
        rules.points.m08Vine = 3000
        #expect(throws: GameRules.ValidationError.outOfRange("points.m08Vine")) {
            try rules.validate()
        }
    }

    @Test func rejectsOutOfRangeCounts() {
        var rules = GameRules.rulebook
        rules.counts.m06Fragments = 0
        #expect(throws: GameRules.ValidationError.outOfRange("counts.m06Fragments")) {
            try rules.validate()
        }
    }

    @Test func rejectsMalformedJSON() {
        let data = Data(#"{"schema": 1, "revision": 2}"#.utf8)
        #expect(throws: DecodingError.self) {
            try GameRules.decode(data)
        }
    }
}
