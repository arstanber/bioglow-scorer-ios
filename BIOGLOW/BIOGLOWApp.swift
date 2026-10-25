//
//  BIOGLOWApp.swift
//  BIOGLOW
//

import Aptabase
import SwiftData
import SwiftUI

let version: String =
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    ?? "Unknown Version"
let build: String =
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown Build"
#if targetEnvironment(simulator)
    let environment: AppEnvironment = .development
#else
    let environment: AppEnvironment = .production
#endif

enum AppEnvironment {
    case production
    case beta
    case alpha
    case development

    var warningLabel: (some View)? {
        switch self {
        case .beta:
            Label(
                "Beta software. Features may be unstable. Use with caution.",
                systemImage: "testtube.2"
            )
            .foregroundStyle(.orange)
        case .alpha:
            Label(
                "Alpha software. For internal testing only.\nDistribution without permission is prohibited.",
                systemImage: "hand.raised.fill"
            )
            .foregroundStyle(.red)
        case .development:
            Label(
                "Development build. Distribution without permission is prohibited.",
                systemImage: "hammer.fill"
            )
            .foregroundStyle(.indigo)
        default:
            nil
        }
    }
}

@main
struct BIOGLOWApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RobotGameMatchModel.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        Analytics.shared.launch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .themedBackground()
        }
        .modelContainer(sharedModelContainer)
    }
}
