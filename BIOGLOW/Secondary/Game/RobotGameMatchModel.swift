//
//  RobotGameMatchModel.swift
//  BIOGLOW
//

import Foundation
import SwiftData

enum MatchRound: String, Codable, Hashable, CaseIterable {
    case practice = "Practice"
    case round1 = "Round 1"
    case round2 = "Round 2"
    case round3 = "Round 3"

    /// Rounds 1–3 count toward the ranking.
    var isOfficial: Bool { self != .practice }

    var shortTitle: String {
        switch self {
        case .practice: "P"
        case .round1: "R1"
        case .round2: "R2"
        case .round3: "R3"
        }
    }
}

@Model
final class RobotGameMatchModel {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    var teamNumber: String? = nil
    private var roundRaw: String = MatchRound.practice.rawValue
    @Attribute(.externalStorage) private var scoresData: Data? = nil
    @Attribute(.externalStorage) private var logData: Data? = nil

    init(
        scores: BioGlowScores,
        teamNumber: String? = nil,
        round: MatchRound = .practice,
        log: [MatchLogEntry] = [],
        timestamp: Date = Date()
    ) {
        self.id = UUID().uuidString
        self.timestamp = timestamp
        self.teamNumber = Self.normalized(teamNumber)
        self.roundRaw = round.rawValue
        self.scoresData = try? JSONEncoder().encode(scores)
        self.logData = log.isEmpty ? nil : try? JSONEncoder().encode(log)
    }

    var round: MatchRound {
        get { MatchRound(rawValue: roundRaw) ?? .practice }
        set { roundRaw = newValue.rawValue }
    }

    var log: [MatchLogEntry] {
        logData.flatMap {
            try? JSONDecoder().decode([MatchLogEntry].self, from: $0)
        } ?? []
    }

    var scores: BioGlowScores {
        get {
            scoresData.flatMap {
                try? JSONDecoder().decode(BioGlowScores.self, from: $0)
            } ?? .init()
        }
        set { scoresData = try? JSONEncoder().encode(newValue) }
    }

    var teamLabel: String {
        teamNumber.map { "Team \($0)" } ?? "No team"
    }

    var rankingEntry: RankingEntry {
        RankingEntry(
            teamNumber: teamNumber,
            round: round,
            total: scores.total,
            timestamp: timestamp
        )
    }

    /// Trims whitespace; an empty team number is stored as nil.
    static func normalized(_ teamNumber: String?) -> String? {
        let trimmed = teamNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
