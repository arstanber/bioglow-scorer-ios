//
//  RobotGameClock.swift
//  BIOGLOW
//
//  The 2:30 robot game clock, described by dates instead of a ticking counter
//  so a Watch app or Live Activity can count down on its own later.
//

import AVFoundation
import Combine
import Foundation

struct RobotGameClockState: Codable, Hashable {
    enum Phase: String, Codable, Hashable {
        case idle, countdown, match, finished
    }

    static let countdownSeconds: TimeInterval = 3

    var phase: Phase
    /// When the current phase ends. Ignored while paused.
    var phaseEnd: Date
    /// Seconds left in the current phase while paused.
    var pausedRemaining: TimeInterval?
    var matchSeconds: TimeInterval

    static func idle(matchSeconds: Int = GameRules.current.matchSeconds) -> RobotGameClockState {
        RobotGameClockState(
            phase: .idle,
            phaseEnd: .distantPast,
            matchSeconds: TimeInterval(matchSeconds)
        )
    }

    var isPaused: Bool { pausedRemaining != nil }

    var isRunning: Bool {
        phase == .countdown || phase == .match
    }

    var phaseTitle: String {
        switch phase {
        case .idle: "Ready"
        case .countdown: "Get Ready"
        case .match: isPaused ? "Paused" : "Match"
        case .finished: "Match End"
        }
    }

    /// When the match ends, or nil when the clock isn't counting down.
    var matchEnd: Date? {
        guard isRunning, !isPaused else { return nil }
        return phase == .countdown ? phaseEnd.addingTimeInterval(matchSeconds) : phaseEnd
    }

    /// Rolls the clock forward through any phases that ended before `date`.
    func advanced(to date: Date) -> RobotGameClockState {
        var state = self
        while state.isRunning, !state.isPaused, state.phaseEnd <= date {
            switch state.phase {
            case .countdown:
                state.phase = .match
                state.phaseEnd = state.phaseEnd.addingTimeInterval(matchSeconds)
            case .match:
                state.phase = .finished
            case .idle, .finished:
                break
            }
        }
        return state
    }

    /// Seconds left in the current phase.
    func remaining(at date: Date) -> TimeInterval {
        let state = advanced(to: date)
        if let pausedRemaining = state.pausedRemaining { return pausedRemaining }
        switch state.phase {
        case .idle: return matchSeconds
        case .finished: return 0
        case .countdown, .match: return max(0, state.phaseEnd.timeIntervalSince(date))
        }
    }

    /// Whole seconds left in the match, rounded up so the clock starts at 2:30.
    func matchSecondsLeft(at date: Date) -> Int {
        let state = advanced(to: date)
        switch state.phase {
        case .idle, .countdown: return Int(matchSeconds)
        case .finished: return 0
        case .match: return Int(state.remaining(at: date).rounded(.up))
        }
    }

    /// "2:14", "After match", or nil before the match starts.
    func logClock(at date: Date) -> String? {
        let state = advanced(to: date)
        switch state.phase {
        case .idle: return nil
        case .countdown, .match: return Self.format(state.matchSecondsLeft(at: date))
        case .finished: return "After match"
        }
    }

    static func format(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    // MARK: Control

    static func started(
        at date: Date = .now,
        matchSeconds: Int = GameRules.current.matchSeconds
    ) -> RobotGameClockState {
        RobotGameClockState(
            phase: .countdown,
            phaseEnd: date.addingTimeInterval(countdownSeconds),
            matchSeconds: TimeInterval(matchSeconds)
        )
    }

    func paused(at date: Date = .now) -> RobotGameClockState {
        guard isRunning, !isPaused else { return self }
        var state = advanced(to: date)
        guard state.isRunning else { return state }
        state.pausedRemaining = max(0, state.phaseEnd.timeIntervalSince(date))
        return state
    }

    func resumed(at date: Date = .now) -> RobotGameClockState {
        guard let pausedRemaining else { return self }
        var state = self
        state.phaseEnd = date.addingTimeInterval(pausedRemaining)
        state.pausedRemaining = nil
        return state
    }

    func finished() -> RobotGameClockState {
        var state = self
        state.phase = .finished
        state.pausedRemaining = nil
        return state
    }
}

// MARK: - Ticking wrapper

@MainActor
final class RobotGameTimer: ObservableObject {
    @Published private(set) var state: RobotGameClockState = .idle()
    @Published private(set) var now: Date = .now

    private var ticker: AnyCancellable?

    var phase: RobotGameClockState.Phase { state.advanced(to: now).phase }
    var isPaused: Bool { state.isPaused }
    var isRunning: Bool { state.advanced(to: now).isRunning }
    var secondsLeft: Int { state.matchSecondsLeft(at: now) }
    var countdownLeft: Int { Int(state.remaining(at: now).rounded(.up)) }
    var logClock: String? { state.logClock(at: .now) }

    var phaseTitle: String { state.advanced(to: now).phaseTitle }

    func start() {
        state = .started()
        now = .now
        Haptics.play(.medium)
        startTicking()
    }

    func pause() {
        state = state.paused()
        now = .now
    }

    func resume() {
        state = state.resumed()
        now = .now
    }

    func reset() {
        ticker = nil
        state = .idle()
        now = .now
        RobotGameCues.shared.stop()
    }

    /// Ends the match now, e.g. when the robots stop early.
    func finish() {
        ticker = nil
        state = state.finished()
        now = .now
    }

    private func startTicking() {
        ticker = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.tick(date)
            }
    }

    private func tick(_ date: Date) {
        let before = state.advanced(to: now)
        let after = state.advanced(to: date)
        let countdownBefore = Int(before.remaining(at: now).rounded(.up))
        let countdownAfter = Int(after.remaining(at: date).rounded(.up))

        now = date

        if before.phase == .countdown, after.phase == .countdown,
            countdownAfter < countdownBefore
        {
            Haptics.play(.light)
        }
        if before.phase == .countdown, after.phase != .countdown {
            Haptics.notify(.success)
            RobotGameCues.shared.play(.start)
        }
        if before.phase == .match, after.phase == .finished {
            Haptics.notify(.warning)
            RobotGameCues.shared.play(.end)
        }
        if !after.isRunning {
            state = after
            ticker = nil
        }
    }
}

// MARK: - Sounds

@MainActor
final class RobotGameCues {
    static let shared = RobotGameCues()

    enum Cue: String {
        case start, end
    }

    private var players: [Cue: AVAudioPlayer] = [:]

    private init() {
        for cue in [Cue.start, .end] {
            players[cue] = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav")
                .flatMap { try? AVAudioPlayer(contentsOf: $0) }
            players[cue]?.prepareToPlay()
        }
    }

    func play(_ cue: Cue) {
        guard UserDefaults.standard.object(forKey: "soundsEnabled") as? Bool ?? true else { return }
        let player = players[cue]
        player?.currentTime = 0
        player?.play()
    }

    func stop() {
        players.values.forEach { $0.stop() }
    }
}
