//
//  MatchCardExport.swift
//  BIOGLOW
//
//  A shareable image of a robot game result for social media and team chats.
//

import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

enum MatchCardFormat: String, CaseIterable, Identifiable {
    case square = "Square"
    case story = "Story"
    case wide = "Wide"

    var id: String { rawValue }

    /// Output size in points; rendered at 2× scale.
    var size: CGSize {
        switch self {
        case .square: CGSize(width: 540, height: 540)
        case .story: CGSize(width: 540, height: 960)
        case .wide: CGSize(width: 960, height: 540)
        }
    }
}

struct MatchCardView: View {
    let scores: BioGlowScores
    let teamNumber: String?
    let round: MatchRound?
    let timestamp: Date
    var format: MatchCardFormat = .square

    private var scoredMissions: Int {
        Mission.allCases.filter { scores.points(for: $0) > 0 }.count
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: format == .story ? 32 : 18) {
                header

                Spacer(minLength: 0)

                if format == .wide {
                    HStack(alignment: .center, spacing: 24) {
                        VStack(spacing: 18) {
                            total
                            stats
                        }
                        .frame(width: 330)

                        missionGrid
                    }
                } else {
                    total
                    stats
                    missionGrid
                }

                Spacer(minLength: 0)

                footer
            }
            .padding(format == .wide ? 28 : 32)
        }
        .frame(width: format.size.width, height: format.size.height)
        .environment(\.colorScheme, .dark)
    }

    // MARK: Pieces

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.1, blue: 0.02), Color(red: 0.04, green: 0.03, blue: 0.01)],
                startPoint: .top,
                endPoint: .bottom
            )

            FireflyPattern(spacing: 36)
                .fill(Color.glowBright.opacity(0.1))

            RadialGradient(
                colors: [Color.glowBright.opacity(0.3), .clear],
                center: .top,
                startRadius: 10,
                endRadius: format.size.width * 0.8
            )
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("🌿 BIOGLOW")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.glowBright)
                Text(teamNumber.map { "Team \($0)" } ?? "Robot Game")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            if let round {
                Text(round.rawValue.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(round.isOfficial ? Color.brandInk : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        if round.isOfficial {
                            Capsule().fill(.brand)
                        } else {
                            Capsule().fill(.white.opacity(0.15))
                        }
                    }
            }
        }
    }

    private var total: some View {
        VStack(spacing: -6) {
            Text("\(scores.total)")
                .font(.system(size: format == .story ? 168 : 120, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.brand(from: .top, to: .bottom))
                .shadow(color: Color.glowBright.opacity(0.35), radius: 24)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("POINTS")
                .font(.system(size: 15, weight: .heavy))
                .kerning(4)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            stat("Inspection", value: "\(scores.inspectionPoints)")
            stat("Tokens", value: "\(scores.tokenPoints)")
            stat("Missions", value: "\(scoredMissions)/\(Mission.allCases.count)")
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var missionGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
            spacing: 8
        ) {
            ForEach(Mission.allCases) { mission in
                missionChip(mission)
            }
        }
    }

    private func missionChip(_ mission: Mission) -> some View {
        let points = scores.points(for: mission)
        let scored = points > 0
        let maxed = scored && points == mission.maxPoints

        return VStack(spacing: 0) {
            Text(mission.code)
                .font(.system(size: 11, weight: .bold))
                .opacity(0.7)
            Text("\(points)")
                .font(.system(size: format == .story ? 24 : 20, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(scored ? Color.brandInk : .white.opacity(0.4))
        .frame(maxWidth: .infinity)
        .padding(.vertical, format == .story ? 12 : 7)
        .background {
            let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
            if scored {
                shape.fill(.brand(from: .topLeading, to: .bottomTrailing))
            } else {
                shape.fill(.white.opacity(0.07))
            }
        }
        .overlay {
            if maxed {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 2)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(timestamp.formatted(date: .abbreviated, time: .shortened))
            Spacer()
            Text("BIOGLOW Scorer · kita 39112")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.white.opacity(0.5))
    }
}

/// Renders the card lazily when the share sheet asks for it.
struct MatchCardImage: Transferable {
    let scores: BioGlowScores
    let teamNumber: String?
    let round: MatchRound?
    let timestamp: Date
    var format: MatchCardFormat = .square

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            try await card.pngData()
        }
        .suggestedFileName { card in
            ["BIOGLOW", card.teamNumber, "\(card.scores.total)"]
                .compactMap { $0 }
                .joined(separator: " ") + ".png"
        }
    }

    @MainActor
    func render() -> UIImage? {
        let renderer = ImageRenderer(
            content: MatchCardView(
                scores: scores,
                teamNumber: teamNumber,
                round: round,
                timestamp: timestamp,
                format: format
            )
        )
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(format.size)
        return renderer.uiImage
    }

    func pngData() async throws -> Data {
        guard let data = await MainActor.run(body: { render()?.pngData() }) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }
}

/// Preview, format picker and share button.
struct MatchCardShareView: View {
    @Environment(\.dismiss) private var dismiss

    let scores: BioGlowScores
    let teamNumber: String?
    let round: MatchRound?
    let timestamp: Date

    @State private var format: MatchCardFormat = .square

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let available = CGSize(width: proxy.size.width - 32, height: proxy.size.height - 32)
                let scale = min(available.width / format.size.width, available.height / format.size.height, 1)

                MatchCardView(
                    scores: scores,
                    teamNumber: teamNumber,
                    round: round,
                    timestamp: timestamp,
                    format: format
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .scaleEffect(scale)
                .frame(width: format.size.width * scale, height: format.size.height * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(radius: 12)
            }
            .navigationTitle("Share Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DismissButton {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Picker("Format", selection: $format) {
                        ForEach(MatchCardFormat.allCases) { format in
                            Text(format.rawValue)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    let card = MatchCardImage(
                        scores: scores,
                        teamNumber: teamNumber,
                        round: round,
                        timestamp: timestamp,
                        format: format
                    )
                    ShareLink(
                        item: card,
                        preview: SharePreview("BIOGLOW result", image: Image(systemName: "leaf.fill"))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

#Preview {
    MatchCardView(
        scores: .completed,
        teamNumber: "39112",
        round: .round1,
        timestamp: .now
    )
}
