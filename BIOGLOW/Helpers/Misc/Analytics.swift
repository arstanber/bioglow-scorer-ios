//
//  Analytics.swift
//  BIOGLOW
//

import Aptabase
import SwiftUI

class Analytics: ObservableObject {
    static var shared = Analytics()

    @AppStorage("matchesTracked") var matchesTracked: Int = 0
    @AppStorage("calcSessionsTracked") var calcSessionsTracked: Int = 0
    @AppStorage("missionsTracked") var missionsTracked: Int = 0
    @AppStorage("pointsTracked") var pointsTracked: Int = 0

    func launch() {
        if !APTABASE_APP_KEY.isEmpty {
            Aptabase.shared.initialize(
                appKey: APTABASE_APP_KEY,
                with: .init(
                    trackingMode: [AppEnvironment.development, .alpha].contains(
                        BIOGLOW.environment
                    ) ? .asDebug : .asRelease
                )
            )
            Aptabase.shared.trackEvent("launch")
        }
    }

    func trackFeature(_ type: FeatureTrackingType) {
        guard !APTABASE_APP_KEY.isEmpty else { return }
        Aptabase.shared.trackEvent("feature", with: ["feature": type.rawValue])
    }

    /// Called when a scoring session is reset, saved or exited.
    func trackCompletion(_ scores: BioGlowScores, from type: CompletionTrackingType) {
        guard !scores.isBlank else { return }

        switch type {
        case .game: matchesTracked += 1
        case .calc: calcSessionsTracked += 1
        }

        let missions = Mission.allCases.filter { scores.points(for: $0) > 0 }.count
        missionsTracked += missions
        pointsTracked += scores.total

        if !APTABASE_APP_KEY.isEmpty {
            Aptabase.shared.trackEvent(
                "completion",
                with: [
                    "missions": missions,
                    "tokens": scores.precisionTokens,
                    "total": scores.total,
                    "type": type.rawValue,
                ]
            )
        }
    }

    enum FeatureTrackingType: String {
        case game = "Score Match"
        case history = "History & Rankings"
        case timer = "Timer"
        case calc = "Calculator"
    }

    enum CompletionTrackingType: String {
        case game = "Score Match"
        case calc = "Calculator"
    }
}
