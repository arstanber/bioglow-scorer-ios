//
//  StartDelay.swift
//  BIOGLOW
//
//  An optional countdown before the robot game timer starts, so there is
//  time to put the phone down and step back from the robot.
//

import Combine
import SwiftUI

@MainActor
final class StartDelay: ObservableObject {
    /// Seconds chosen in Settings; 0 starts right away.
    static let storageKey = "timerStartDelay"
    static let options = [0, 3, 5, 10]

    /// Seconds left before the timer starts, or nil when not counting down.
    @Published private(set) var remaining: Int? = nil

    private var task: Task<Void, Never>?

    /// Runs `start` after the delay chosen in Settings.
    func run(_ start: @escaping () -> Void) {
        cancel()

        let seconds = UserDefaults.standard.integer(forKey: Self.storageKey)
        guard seconds > 0 else {
            start()
            return
        }

        remaining = seconds
        Haptics.play(.light)

        task = Task { [weak self] in
            for left in stride(from: seconds - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }

                if left == 0 {
                    self.remaining = nil
                    self.task = nil
                    start()
                } else {
                    self.remaining = left
                    Haptics.play(left <= 3 ? .medium : .light)
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        remaining = nil
    }
}

struct StartDelayPicker: View {
    @AppStorage(StartDelay.storageKey) private var delay: Int = 0

    var body: some View {
        Picker("Start Delay", selection: $delay) {
            ForEach(StartDelay.options, id: \.self) { seconds in
                if seconds == 0 {
                    Text("Off").tag(seconds)
                } else {
                    Text("\(seconds) sec").tag(seconds)
                }
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
