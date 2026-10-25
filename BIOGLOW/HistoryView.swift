//
//  HistoryView.swift
//  BIOGLOW
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \RobotGameMatchModel.timestamp, order: .reverse) private var matches:
        [RobotGameMatchModel]

    @State private var search: String = ""
    @State private var editingTeamFor: RobotGameMatchModel? = nil
    @State private var editedTeam: String = ""

    private var filteredMatches: [RobotGameMatchModel] {
        guard !search.isEmpty else { return matches }

        return matches.filter { match in
            "\(match.teamLabel) \(match.round.rawValue) \(match.timestamp.formatted()) \(match.scores.total)"
                .localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    stats

                    Section {
                        NavigationLink {
                            TeamRankingsView(entries: matches.map(\.rankingEntry))
                        } label: {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Rankings")
                                        .font(.headline)
                                    Text("Best of Rounds 1–3, tiebreak on 2nd and 3rd")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "list.number")
                            }
                        }
                    }
                }

                Section {
                    if matches.isEmpty {
                        Text("No Saved Matches")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    ForEach(filteredMatches) { match in
                        NavigationLink(value: match) {
                            row(match)
                        }
                    }
                    .onDelete { offsets in
                        withAnimation {
                            let visible = filteredMatches
                            for index in offsets {
                                modelContext.delete(visible[index])
                            }
                            saveContext()
                        }
                    }
                } header: {
                    Label("Matches", systemImage: "flag.checkered")
                }
                .headerProminence(.increased)
            }
            .searchable(text: $search)
            .navigationDestination(for: RobotGameMatchModel.self) { match in
                detail(match)
            }
            .navigationTitle("History & Rankings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DismissButton {
                        dismiss()
                    }
                }
            }
        }
        .alert(
            "Team Number",
            isPresented: Binding(
                get: { editingTeamFor != nil },
                set: { if !$0 { editingTeamFor = nil } }
            )
        ) {
            TextField("Team number", text: $editedTeam)
                .keyboardType(.numberPad)
            Button("Save") {
                editingTeamFor?.teamNumber = RobotGameMatchModel.normalized(editedTeam)
                saveContext()
                editingTeamFor = nil
            }
            Button("Cancel", role: .cancel) {
                editingTeamFor = nil
            }
        }
    }

    private func row(_ match: RobotGameMatchModel) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(match.teamLabel)
                    .font(.headline)

                Text("\(match.round.rawValue) · \(match.timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(match.scores.total)")
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(match.round.isOfficial ? Color.brandInk : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    if match.round.isOfficial {
                        Rectangle().fill(.brand)
                    } else {
                        Rectangle().fill(Color.secondary.gradient)
                    }
                }
                .radius(12)
        }
    }

    private func detail(_ match: RobotGameMatchModel) -> some View {
        let scores = match.scores

        return ScrollView {
            VStack(spacing: 12) {
                MatchHeader(
                    timestamp: match.timestamp,
                    teamNumber: match.teamNumber,
                    round: match.round,
                    total: scores.total
                )

                ScoreDetailsView(scores: scores)

                let log = match.log
                if !log.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Match Log", systemImage: "list.bullet.rectangle")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        ForEach(log) { entry in
                            MatchLogRow(entry: entry)
                            Divider()
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedSurface(24)
                }
            }
            .padding(16)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: scores.summary(
                        teamNumber: match.teamNumber,
                        round: match.round,
                        timestamp: match.timestamp
                    )
                )
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Edit Team Number", systemImage: "person.fill") {
                        editedTeam = match.teamNumber ?? ""
                        editingTeamFor = match
                    }

                    Picker(
                        selection: Binding(
                            get: { match.round },
                            set: { round in
                                match.round = round
                                saveContext()
                            }
                        )
                    ) {
                        ForEach(MatchRound.allCases, id: \.self) { round in
                            Text(round.rawValue)
                                .tag(round)
                        }
                    } label: {
                        Label("Round", systemImage: "flag.checkered")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                try? modelContext.save()
            }
        }
    }

    private var stats: some View {
        let official = matches.filter(\.round.isOfficial)
        let best = official.map(\.scores.total).max()
        let teams = Set(official.compactMap(\.teamNumber)).count

        return Section {
        } header: {
            HStack(spacing: 12) {
                statTile(
                    title: "Matches",
                    value: "\(matches.count)",
                    detail: "\(official.count) official",
                    color: .moss
                )

                statTile(
                    title: "Best Score",
                    value: best.map { "\($0)" } ?? "—",
                    detail: "\(teams) team\(teams == 1 ? "" : "s") ranked",
                    color: .glow
                )
            }
        }
        .headerProminence(.increased)
    }

    private func statTile(title: String, value: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
            Text(value)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .monospacedDigit()
            Text(detail)
                .font(.subheadline)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .textCase(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .themedTile(color, radius: 24)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: RobotGameMatchModel.self, inMemory: true)
}
