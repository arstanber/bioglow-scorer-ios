//
//  ContentView.swift
//  BIOGLOW
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Namespace private var zoom

    @State private var showScoreView: Bool = false
    @State private var showHistoryView: Bool = false
    @State private var showTimerView: Bool = false
    @State private var showCalculatorView: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height

            Group {
                if landscape {
                    HStack(spacing: 8) {
                        VStack(spacing: 8) {
                            titleBar
                                .frame(height: 64)
                            historyTile
                            HStack(spacing: 8) {
                                timerTile
                                calculatorTile
                            }
                            settingsTile
                                .frame(height: 64)
                        }

                        scoreTile
                    }
                } else {
                    VStack(spacing: 8) {
                        titleBar
                            .frame(height: 64)
                        scoreTile
                            .layoutPriority(1)
                        HStack(spacing: 8) {
                            timerTile
                            calculatorTile
                        }
                        .frame(height: proxy.size.height * 0.16)
                        historyTile
                            .frame(height: proxy.size.height * 0.14)
                        settingsTile
                            .frame(height: 64)
                    }
                }
            }
        }
        .padding(12)
        .fullScreenCover(isPresented: $showScoreView) {
            RobotGameScoreView()
                .themedBackground()
                .modelContext(modelContext)
                .zoomTransition("score", in: zoom)
        }
        .sheet(isPresented: $showHistoryView) {
            HistoryView()
                .themedBackground()
                .modelContext(modelContext)
                .zoomTransition("history", in: zoom)
        }
        .fullScreenCover(isPresented: $showTimerView) {
            TimerView()
                .themedBackground()
                .zoomTransition("timer", in: zoom)
        }
        .fullScreenCover(isPresented: $showCalculatorView) {
            CalculatorView()
                .themedBackground()
                .modelContext(modelContext)
                .zoomTransition("calculator", in: zoom)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .themedBackground()
                .zoomTransition("settings", in: zoom)
        }
        .onOpenURL { url in
            guard url.scheme == "bioglow-scorer" else { return }
            switch url.host() {
            case "score": showScoreView = true
            case "timer": showTimerView = true
            case "calculator": showCalculatorView = true
            case "history": showHistoryView = true
            case "settings": showSettings = true
            default: break
            }
        }
    }

    // MARK: Tiles

    private var titleBar: some View {
        HStack(spacing: 8) {
            (Text("🌿 ")
                + Text("BIOGLOW")
                .fontWeight(.bold)
                .fontDesign(.monospaced)
                + Text("™")
                .fontWeight(.light)
                .fontDesign(.monospaced)
                + Text(" Scorer"))
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 20)
                .maxArea(alignment: .leading)
                .themedSurface(16)

            Link(destination: URL(string: "https://www.instagram.com/arstanber")!) {
                Image("Instagram")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
                    .padding(18)
                    .aspectRatio(1, contentMode: .fit)
                    .themedSurface(16)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Instagram")
        }
    }

    private var scoreTile: some View {
        Button {
            Haptics.play(.light)
            showScoreView = true
            Analytics.shared.trackFeature(.game)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.largeTitle)
                    .symbolEffect(.bounce, value: showScoreView)

                Text("Score Match")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("2:30 timer · 15 missions")
                    .font(.headline)
                    .opacity(0.8)
            }
            .minimumScaleFactor(0.6)
            .padding()
            .maxArea()
            .themedBrandTile()
        }
        .buttonStyle(.pressable)
        .zoomSource("score", in: zoom)
    }

    private var timerTile: some View {
        tile("Timer", icon: "timer", color: .firefly, zoomID: "timer") {
            showTimerView = true
            Analytics.shared.trackFeature(.timer)
        }
    }

    private var calculatorTile: some View {
        tile("Calculator", icon: "plus.slash.minus", color: .moss, zoomID: "calculator") {
            showCalculatorView = true
            Analytics.shared.trackFeature(.calc)
        }
    }

    private var historyTile: some View {
        tile("History & Rankings", icon: "list.number", color: .spore, zoomID: "history") {
            showHistoryView = true
            Analytics.shared.trackFeature(.history)
        }
    }

    private var settingsTile: some View {
        tile("Settings", icon: "gear", color: .bark, zoomID: "settings") {
            showSettings = true
        }
    }

    private func tile(
        _ title: String,
        icon: String,
        color: Color,
        zoomID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.play(.light)
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .minimumScaleFactor(0.6)
            .padding()
            .maxArea()
            .themedTile(color)
        }
        .buttonStyle(.pressable)
        .zoomSource(zoomID, in: zoom)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RobotGameMatchModel.self, inMemory: true)
}
