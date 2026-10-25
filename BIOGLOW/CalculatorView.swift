//
//  CalculatorView.swift
//  BIOGLOW
//

import SwiftUI

/// The match scorer without a timer, for working out a score after the fact.
struct CalculatorView: View {
    var body: some View {
        RobotGameScoreView(showsTimer: false)
    }
}

#Preview {
    CalculatorView()
}
