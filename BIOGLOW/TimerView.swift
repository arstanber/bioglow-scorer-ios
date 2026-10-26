//
//  TimerView.swift
//  BIOGLOW
//

import SwiftUI

/// A full-screen 2:30 robot game timer.
struct TimerView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var timer = RobotGameTimer()
    @StateObject private var startDelay = StartDelay()

    var body: some View {
        let phase = timer.phase
        let finalSeconds = phase == .match && timer.secondsLeft <= 10 && !timer.isPaused

        VStack {
            HStack {
                Button {
                    startDelay.cancel()
                    timer.reset()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Exit")

                Spacer()
            }
            .tint(.primary)

            Spacer()

            Text(
                startDelay.remaining.map { "\($0)" }
                    ?? (phase == .countdown
                        ? "\(timer.countdownLeft)"
                        : RobotGameClockState.format(timer.secondsLeft))
            )
            .scoreDigits(512, weight: .semibold, glow: finalSeconds ? .firefly : nil)
            .minimumScaleFactor(0.2)
            .lineLimit(1)
            .contentTransition(.numericText())
            .animation(.smooth, value: timer.secondsLeft)
            .animation(.smooth, value: timer.countdownLeft)
            .animation(.smooth, value: startDelay.remaining)
            .foregroundStyle(finalSeconds ? Color.firefly : .primary)

            Text(startDelay.remaining != nil ? "Starting in…" : timer.phaseTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(finalSeconds ? Color.firefly : .secondary)
                .pulse(finalSeconds, color: .firefly)
                .contentTransition(.opacity)

            Spacer()

            HStack(spacing: 16) {
                switch phase {
                case .idle where startDelay.remaining != nil:
                    Button {
                        Haptics.play(.light)
                        withAnimation(.smooth) { startDelay.cancel() }
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.primary)
                case .idle:
                    Button {
                        startDelay.run {
                            withAnimation(.smooth) { timer.start() }
                        }
                    } label: {
                        Label("Start Match", systemImage: "play.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                case .countdown, .match:
                    Button {
                        withAnimation(.smooth) {
                            timer.isPaused ? timer.resume() : timer.pause()
                        }
                    } label: {
                        Label(timer.isPaused ? "Resume" : "Pause", systemImage: timer.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)

                    resetButton
                case .finished:
                    resetButton
                }
            }
            .buttonBorderShape(.capsule)
        }
        .padding()
    }

    private var resetButton: some View {
        Button {
            withAnimation(.smooth) { timer.reset() }
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(.primary)
    }
}

#Preview {
    TimerView()
}
