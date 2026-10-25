//
//  ScoreDetailsView.swift
//  BIOGLOW
//

import SwiftUI

struct ScoreDetailsView: View {
    let scores: BioGlowScores

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                NumericCard(
                    icon: "ruler",
                    name: "Inspection",
                    value: scores.inspectionPoints,
                    detail: scores.inspectionPassed ? "Passed" : "Not passed"
                )

                NumericCard(
                    icon: "circle.hexagongrid.circle",
                    name: "Tokens",
                    value: scores.tokenPoints,
                    detail: "\(scores.precisionTokens) left"
                )

                NumericCard(
                    icon: "hands.sparkles",
                    name: "GP",
                    value: scores.gp.rawValue,
                    detail: "\(scores.gp.title) · not scored",
                    tint: .spore
                )
            }
            .fixedSize(horizontal: false, vertical: true)

            ScoreBreakdownCard(scores: scores)
        }
    }
}

struct MatchHeader: View {
    let timestamp: Date
    let teamNumber: String?
    let round: MatchRound?
    let total: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(timestamp.formatted(date: .complete, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(teamNumber.map { "Team \($0)" } ?? "No team")
                if let round {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(round.rawValue)
                }
            }
            .font(.title2)
            .fontWeight(.semibold)

            Text("\(total)")
                .scoreDigits(56, glow: .glow)
                .foregroundStyle(Color.brandInk)
                .padding(.horizontal, 24)
                .padding(.vertical, 2)
                .themedBrandTile(radius: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NumericCard: View {
    let icon: String
    let name: String
    let value: Int
    let detail: String
    var tint: Color = .glow

    var body: some View {
        VStack(spacing: -8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)

                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .zIndex(1)
            .glassBackground()

            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(detail)
                    .font(.caption2)
                    .opacity(0.85)
                    .lineLimit(1)
            }
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background((value > 0 ? tint : Color.secondary.opacity(0.8)).gradient)
            .radius(16)
            .zIndex(0)
        }
    }
}

/// "Why this score": every source of points.
struct ScoreBreakdownCard: View {
    let scores: BioGlowScores

    var body: some View {
        VStack(spacing: 8) {
            Text("Why this score")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .glassBackground()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(scores.breakdown()) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 4) {
                                Text(line.label)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                if line.noEquipmentConstraint {
                                    Image(systemName: "shippingbox")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("No equipment constraint")
                                }
                            }
                            Text(line.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 4)
                        Text("+\(line.points)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(line.points > 0 ? .primary : .secondary)
                            .frame(minWidth: 36, alignment: .trailing)
                    }
                    .opacity(line.points > 0 ? 1 : 0.6)
                }

                Divider()

                HStack {
                    Text("Robot game total")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(scores.total)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .foregroundStyle(Color.glow)

                HStack {
                    Text("Gracious Professionalism (separate)")
                        .font(.caption)
                    Spacer()
                    Text("\(scores.gp.rawValue) · \(scores.gp.title)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.glow.opacity(0.06))
            .radius(16)
        }
        .padding(8)
        .themedSurface(24)
    }
}

extension BioGlowScores {
    func summary(teamNumber: String?, round: MatchRound?, timestamp: Date) -> String {
        var header = "🌿 BIOGLOW robot game"
        if let teamNumber { header += " — Team \(teamNumber)" }
        if let round { header += " · \(round.rawValue)" }

        var lines = [
            header,
            timestamp.formatted(date: .abbreviated, time: .shortened),
            "Score: \(total)",
            "Inspection \(inspectionPoints) · Tokens \(tokenPoints) (\(precisionTokens) left)",
        ]

        for mission in Mission.allCases where points(for: mission) > 0 {
            lines.append("\(mission.code) \(mission.name): \(points(for: mission))")
        }

        lines.append("GP \(gp.rawValue) (\(gp.title))")
        lines.append("Scored with the BIOGLOW Scorer by kita 39112")
        return lines.joined(separator: "\n")
    }
}

#Preview {
    ScrollView {
        ScoreDetailsView(scores: .completed)
            .safeAreaPadding()
    }
}
