//
//  RobotGameScoreView.swift
//  BIOGLOW
//
//  Scores one robot game match: the 2:30 timer, all 15 missions, equipment
//  inspection, precision tokens and Gracious Professionalism.
//

import SwiftData
import SwiftUI

struct RobotGameScoreView: View {
    /// The calculator hides the timer.
    var showsTimer: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var timer = RobotGameTimer()
    @StateObject private var startDelay = StartDelay()
    @State private var scores: BioGlowScores = .init()
    @State private var timestamp: Date = .now

    @State private var events: [ScoringEvent] = []
    @State private var isRestoring: Bool = false
    @State private var undoToast: String? = nil

    @State private var showLog: Bool = false
    @State private var showDetails: Bool = false
    @State private var showSettings: Bool = false
    @State private var showSave: Bool = false
    @State private var confirmExit: Bool = false

    @Query private var savedMatches: [RobotGameMatchModel]

    @AppStorage("scoringTeamNumber") private var teamNumber: String = ""
    @AppStorage("scoringRound") private var round: MatchRound = .round1
    @AppStorage("preserveTeamsAfterResetting") private
        var preserveTeamsAfterResetting: Bool = false
    @AppStorage("preserveTeamsAfterExiting") private
        var preserveTeamsAfterExiting: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 640

            VStack(spacing: 0) {
                topBar(wide: wide)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        matchRow(wide: wide)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
                                count: wide ? 2 : 1
                            ),
                            spacing: 12
                        ) {
                            ForEach(Mission.allCases) { mission in
                                MissionCard(mission: mission, scores: $scores)
                            }
                        }

                        bottomRow(wide: wide)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .overlay(alignment: .top) {
            if let undoToast {
                Label(undoToast, systemImage: "arrow.uturn.backward")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 12)
                    .padding(.top, 60)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showDetails) {
            details
        }
        .sheet(isPresented: $showLog) {
            MatchLogView(
                entries: events.map(\.entry),
                canUndo: !events.isEmpty,
                onUndo: undo
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .themedBackground()
        }
        .sheet(isPresented: $showSave) {
            SaveMatchSheet(
                teamNumber: $teamNumber,
                round: $round,
                total: scores.total,
                savedRounds: savedRounds(for:),
                onSave: save
            )
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Discard this match?",
            isPresented: $confirmExit,
            titleVisibility: .visible
        ) {
            Button("Discard and Exit", role: .destructive) {
                exit()
            }
            Button("Save First") {
                showSave = true
            }
        } message: {
            Text("The scores haven't been saved.")
        }
        .onAppear {
            if !preserveTeamsAfterExiting {
                teamNumber = ""
            }
        }
        .onChange(of: scores) { old, new in
            record(old: old, new: new)
        }
    }

    // MARK: - Top bar

    @ViewBuilder
    private func topBar(wide: Bool) -> some View {
        if wide || !showsTimer {
            HStack(spacing: 12) {
                controls
                if showsTimer {
                    MatchTimerBar(timer: timer, startDelay: startDelay)
                }
                Spacer(minLength: 0)
                totalTile
            }
        } else {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    controls
                    Spacer(minLength: 0)
                    totalTile
                }
                MatchTimerBar(timer: timer, startDelay: startDelay)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Save", systemImage: "square.and.arrow.down") {
                    showSave = true
                }
                .disabled(scores.isBlank)

                Button("Details", systemImage: "list.dash") {
                    showDetails = true
                }

                Button("Match Log", systemImage: "list.bullet.rectangle") {
                    showLog = true
                }

                Button("Reset", systemImage: "arrow.2.circlepath", role: .destructive) {
                    reset()
                }

                Divider()

                Button("Settings", systemImage: "gear") {
                    showSettings = true
                }

                Divider()

                Button("Exit", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    if scores.isBlank {
                        exit()
                    } else {
                        confirmExit = true
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .frame(width: 22, height: 22)
            }
            .menuOrder(.fixed)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Menu")

            Button {
                undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .disabled(events.isEmpty)
            .accessibilityLabel("Undo")

            Button {
                showLog = true
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Match Log")
        }
        .tint(.primary)
    }

    private var totalTile: some View {
        Button {
            Haptics.play(.light)
            showDetails = true
        } label: {
            VStack(spacing: -4) {
                Text("\(scores.total)")
                    .scoreDigits(40, glow: .glow)
                    .contentTransition(.numericText())
                    .animation(.smooth, value: scores.total)
                Text("points")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .opacity(0.8)
            }
            .frame(minWidth: 72)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .themedBrandTile()
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Total \(scores.total) points. Show details.")
    }

    // MARK: - Match row

    @ViewBuilder
    private func matchRow(wide: Bool) -> some View {
        if wide {
            HStack(alignment: .top, spacing: 12) {
                inspectionCard
                PrecisionTokensCard(scores: $scores)
                    .frame(maxWidth: .infinity)
                opposingTeamCard
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    inspectionCard
                    opposingTeamCard
                }
                .fixedSize(horizontal: false, vertical: true)

                PrecisionTokensCard(scores: $scores)
            }
        }
    }

    private var inspectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleTile(
                title: "Inspection",
                subtitle: "\(BioGlowPoints.points.inspection) pts",
                icon: "ruler",
                isOn: $scores.inspectionPassed
            )
            .frame(minHeight: 72)

            Text("All equipment fits in one launch area, 305 mm tall")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .themedSurface(16)
    }

    private var opposingTeamCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleTile(
                title: "Opposing Team",
                subtitle: scores.hasOpposingTeam ? "Across the table" : "Remote play",
                icon: "person.2",
                isOn: $scores.hasOpposingTeam
            )
            .frame(minHeight: 72)

            Text("Needed for the M07 bonus. Turn off for remote play.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .themedSurface(16)
    }

    // MARK: - Bottom

    @ViewBuilder
    private func bottomRow(wide: Bool) -> some View {
        let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 12)) : AnyLayout(VStackLayout(spacing: 12))

        layout {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Gracious Professionalism", systemImage: "hands.sparkles")
                        .font(.headline)
                    Spacer()
                }
                HStack(spacing: 6) {
                    ForEach(GraciousProfessionalism.allCases, id: \.self) { gp in
                        SelectorItem(
                            name: "\(gp.rawValue)",
                            subtitle: gp.title,
                            value: gp,
                            selection: $scores.gp
                        )
                    }
                }
                .frame(height: 52)
                Text("Recorded with the match. Not part of the robot game score.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .themedSurface(16)

            Button {
                Haptics.play(.light)
                showSave = true
            } label: {
                Label("Save Match", systemImage: "square.and.arrow.down.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: wide ? 112 : 56)
                    .themedTile(.moss)
            }
            .buttonStyle(.pressable)
            .disabled(scores.isBlank)
        }
    }

    // MARK: - Details

    private var details: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    MatchHeader(
                        timestamp: timestamp,
                        teamNumber: RobotGameMatchModel.normalized(teamNumber),
                        round: nil,
                        total: scores.total
                    )

                    ScoreDetailsView(scores: scores)
                }
                .padding(16)
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DismissButton {
                        showDetails = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: scores.summary(
                            teamNumber: RobotGameMatchModel.normalized(teamNumber),
                            round: nil,
                            timestamp: timestamp
                        )
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func savedRounds(for team: String) -> Set<MatchRound> {
        guard let team = RobotGameMatchModel.normalized(team) else { return [] }
        return Set(savedMatches.filter { $0.teamNumber == team }.map(\.round))
    }

    private func record(old: BioGlowScores, new: BioGlowScores) {
        if isRestoring {
            isRestoring = false
            return
        }

        let changes = new.changes(from: old)
        guard !changes.isEmpty else { return }

        // Merge quick successive edits to the same fields.
        if var last = events.last,
            Date.now.timeIntervalSince(last.date) < 2,
            last.changes.map(\.key) == changes.map(\.key)
        {
            last.changes = new.changes(from: last.previous)
            last.date = .now
            last.clock = showsTimer ? timer.logClock : nil

            if last.changes.isEmpty {
                events.removeLast()
            } else {
                events[events.count - 1] = last
            }
            return
        }

        events.append(
            ScoringEvent(
                date: .now,
                clock: showsTimer ? timer.logClock : nil,
                changes: changes,
                previous: old
            )
        )
    }

    func undo() {
        guard let last = events.popLast() else { return }

        if last.previous != scores {
            isRestoring = true
            scores = last.previous
        }

        Haptics.notify(.warning)
        withAnimation(.smooth) {
            undoToast = last.entry.text
        }

        let text = last.entry.text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if undoToast == text {
                withAnimation(.smooth) {
                    undoToast = nil
                }
            }
        }
    }

    private func save() {
        modelContext.insert(
            RobotGameMatchModel(
                scores: scores,
                teamNumber: teamNumber,
                round: round,
                log: events.map(\.entry),
                timestamp: timestamp
            )
        )

        do {
            try modelContext.save()
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                try? modelContext.save()
            }
        }

        Haptics.notify(.success)
        reset()
    }

    private func reset() {
        Analytics.shared.trackCompletion(scores, from: showsTimer ? .game : .calc)

        startDelay.cancel()
        timer.reset()
        let hasOpposingTeam = scores.hasOpposingTeam
        var blank = BioGlowScores()
        blank.hasOpposingTeam = hasOpposingTeam
        if blank != scores {
            isRestoring = true
            scores = blank
        }
        timestamp = .now
        events = []

        if !preserveTeamsAfterResetting {
            teamNumber = ""
        }
    }

    private func exit() {
        reset()
        dismiss()
    }
}

// MARK: - Timer bar

struct MatchTimerBar: View {
    @ObservedObject var timer: RobotGameTimer
    @ObservedObject var startDelay: StartDelay

    var body: some View {
        let phase = timer.phase
        let finalSeconds = phase == .match && timer.secondsLeft <= 10 && !timer.isPaused

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: -2) {
                Text(
                    startDelay.remaining.map { "\($0)" }
                        ?? (phase == .countdown
                            ? "\(timer.countdownLeft)"
                            : RobotGameClockState.format(timer.secondsLeft))
                )
                .scoreDigits(30, weight: .semibold, glow: finalSeconds ? .firefly : nil)
                .foregroundStyle(finalSeconds ? Color.firefly : .primary)
                .contentTransition(.numericText())
                .animation(.smooth, value: timer.secondsLeft)

                Text(startDelay.remaining != nil ? "Starting in…" : timer.phaseTitle)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 72, alignment: .leading)

            Spacer(minLength: 0)

            switch phase {
            case .idle where startDelay.remaining != nil:
                Button {
                    Haptics.play(.light)
                    startDelay.cancel()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            case .idle:
                Button {
                    startDelay.run { timer.start() }
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            case .countdown, .match:
                Button {
                    Haptics.play(.light)
                    timer.isPaused ? timer.resume() : timer.pause()
                } label: {
                    Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel(timer.isPaused ? "Resume" : "Pause")
                .contextMenu {
                    Button("End Match Now", systemImage: "stop.fill") {
                        timer.finish()
                    }
                }

                resetButton
            case .finished:
                resetButton
            }
        }
        .tint(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: 360)
        .themedSurface(16, tint: finalSeconds ? .firefly : (timer.isPaused ? .secondary : nil))
        .pulse(finalSeconds, color: .firefly)
    }

    private var resetButton: some View {
        Button {
            Haptics.play(.light)
            timer.reset()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Reset Timer")
    }
}

// MARK: - Precision tokens

struct PrecisionTokensCard: View {
    @Binding var scores: BioGlowScores

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Precision Tokens", systemImage: "circle.hexagongrid.circle")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                PointsBadge(points: scores.tokenPoints)
            }

            HStack(spacing: 6) {
                ForEach(0..<GameRules.maxTokens, id: \.self) { index in
                    let filled = index < scores.precisionTokens
                    Button {
                        Haptics.play(.light)
                        // Tapping the last token left removes it; any other sets the count.
                        scores.precisionTokens = index + 1 == scores.precisionTokens ? index : index + 1
                    } label: {
                        Circle()
                            .fill(filled ? AnyShapeStyle(Color.glow.gradient) : AnyShapeStyle(Color.clear))
                            .stroke(filled ? Color.clear : Color.secondary, lineWidth: 1.5)
                            .frame(maxWidth: 34, maxHeight: 34)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Token \(index + 1)")
                    .accessibilityValue(filled ? "Left" : "Lost")
                }
            }
            .frame(height: 34)
            .animation(.smooth, value: scores.precisionTokens)

            Button {
                Haptics.notify(.warning)
                scores.interrupt()
            } label: {
                Label("Interruption −1", systemImage: "hand.raised.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .themedTile(.bark, radius: 12)
            }
            .buttonStyle(.pressable)
            .disabled(scores.precisionTokens == 0)
        }
        .padding(10)
        .themedSurface(16)
    }
}

// MARK: - Save

struct SaveMatchSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var teamNumber: String
    @Binding var round: MatchRound
    let total: Int
    let savedRounds: (String) -> Set<MatchRound>
    let onSave: () -> Void

    @FocusState private var teamFocused: Bool

    var body: some View {
        let taken = savedRounds(teamNumber)

        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Robot game score")
                        Spacer()
                        Text("\(total)")
                            .scoreDigits(28)
                    }
                }

                Section {
                    TextField("Team number", text: $teamNumber)
                        .keyboardType(.numberPad)
                        .focused($teamFocused)
                        .font(.title3)
                } header: {
                    Text("Team")
                } footer: {
                    Text("Matches without a team number are saved but don't appear in rankings.")
                }

                Section {
                    Picker("Round", selection: $round) {
                        ForEach(MatchRound.allCases, id: \.self) { round in
                            Text(round.rawValue).tag(round)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Round")
                } footer: {
                    if round.isOfficial && taken.contains(round) {
                        Label(
                            "Team \(teamNumber) already has a \(round.rawValue) match. Rankings use the latest one.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    } else {
                        Text("Rounds 1–3 count toward the ranking. Practice matches don't.")
                    }
                }
            }
            .navigationTitle("Save Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                suggestRound()
                if teamNumber.isEmpty {
                    teamFocused = true
                }
            }
            .onChange(of: teamNumber) {
                suggestRound()
            }
        }
    }

    /// Picks the team's first official round that hasn't been saved yet.
    private func suggestRound() {
        let taken = savedRounds(teamNumber)
        guard !taken.isEmpty, round.isOfficial, taken.contains(round) else { return }
        if let next = MatchRound.allCases.first(where: { $0.isOfficial && !taken.contains($0) }) {
            round = next
        }
    }
}
