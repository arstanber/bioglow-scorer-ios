//
//  TeamRankingsView.swift
//  BIOGLOW
//
//  Robot game ranking: best official score, tiebreak on 2nd, then 3rd.
//

import SwiftUI

/// What the ranking needs from a saved match.
struct RankingEntry: Hashable {
    var teamNumber: String?
    var round: MatchRound
    var total: Int
    var timestamp: Date
}

struct TeamRecord: Identifiable, Hashable {
    let teamNumber: String
    /// Rounds 1–3, highest first. With duplicates, the latest match per round counts.
    var officialScores: [Int]
    /// Rounds saved more than once.
    var duplicateRounds: [MatchRound]

    var id: String { teamNumber }

    var best: Int { score(at: 0) }
    var second: Int { score(at: 1) }
    var third: Int { score(at: 2) }

    private func score(at index: Int) -> Int {
        officialScores.indices.contains(index) ? officialScores[index] : 0
    }

    /// Same best, second and third score.
    func isTied(with other: TeamRecord) -> Bool {
        best == other.best && second == other.second && third == other.third
    }

    static func ranked(_ records: [TeamRecord]) -> [TeamRecord] {
        records.sorted {
            if $0.best != $1.best { return $0.best > $1.best }
            if $0.second != $1.second { return $0.second > $1.second }
            if $0.third != $1.third { return $0.third > $1.third }
            return $0.teamNumber.localizedStandardCompare($1.teamNumber) == .orderedAscending
        }
    }

    /// Teams with at least one official match. Practice matches and matches without a team are ignored.
    static func records(from entries: [RankingEntry]) -> [TeamRecord] {
        var byTeam: [String: [MatchRound: [RankingEntry]]] = [:]

        for entry in entries {
            guard entry.round.isOfficial,
                let team = RobotGameMatchModel.normalized(entry.teamNumber)
            else { continue }
            byTeam[team, default: [:]][entry.round, default: []].append(entry)
        }

        let records = byTeam.map { team, rounds in
            let latest = rounds.values.compactMap { $0.max { $0.timestamp < $1.timestamp } }
            return TeamRecord(
                teamNumber: team,
                officialScores: latest.map(\.total).sorted(by: >),
                duplicateRounds: MatchRound.allCases.filter { (rounds[$0]?.count ?? 0) > 1 }
            )
        }

        return ranked(records)
    }
}

struct TeamRankingsView: View {
    let entries: [RankingEntry]

    @State private var search: String = ""

    var body: some View {
        let records = TeamRecord.records(from: entries)
        let visible = records.enumerated().filter { _, record in
            search.isEmpty || record.teamNumber.localizedCaseInsensitiveContains(search)
        }

        List {
            Section {
                if visible.isEmpty {
                    Text("No teams yet. Save a match as Round 1, 2 or 3 with a team number.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(visible, id: \.element.id) { index, record in
                    row(record, rank: rank(of: index, in: records), records: records, index: index)
                }
            } footer: {
                Text(
                    "Teams rank by their best robot game score from Rounds 1–3, then their second-best, then their third. Practice matches and Gracious Professionalism don't count."
                )
            }
        }
        .searchable(text: $search, prompt: "Search team number")
        .navigationTitle("Rankings")
    }

    /// Tied teams share a rank.
    private func rank(of index: Int, in records: [TeamRecord]) -> Int {
        var rank = index
        while rank > 0 && records[rank - 1].isTied(with: records[index]) {
            rank -= 1
        }
        return rank + 1
    }

    private func row(_ record: TeamRecord, rank: Int, records: [TeamRecord], index: Int) -> some View {
        let tied =
            (index > 0 && records[index - 1].isTied(with: record))
            || (index + 1 < records.count && records[index + 1].isTied(with: record))

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Team \(record.teamNumber)")
                        .font(.headline)
                    Text("\(record.officialScores.count) of 3 rounds")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)

                Spacer()

                metric("Best", record, 0, emphasized: true)
                metric("2nd", record, 1)
                metric("3rd", record, 2)
            }

            if tied {
                Label("All three scores tied", systemImage: "equal.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if !record.duplicateRounds.isEmpty {
                Label(
                    "\(record.duplicateRounds.map(\.rawValue).formatted()) saved more than once. The latest counts.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
    }

    /// A round that hasn't been played shows a dash; it still counts as 0 when sorting.
    private func metric(_ title: String, _ record: TeamRecord, _ index: Int, emphasized: Bool = false) -> some View {
        VStack(spacing: 0) {
            Text(record.officialScores.indices.contains(index) ? "\(record.officialScores[index])" : "—")
                .font(emphasized ? .headline : .subheadline)
                .fontWeight(emphasized ? .bold : .semibold)
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 44)
    }
}
