//
//  GameRules.swift
//  BIOGLOW
//
//  Point values, element counts and the match length that FIRST can change in
//  Challenge Updates. A copy ships in the app; a newer, validated copy can be
//  downloaded and cached so scoring stays current without an App Store update.
//

import Foundation

struct GameRules: Codable, Hashable {
    static let supportedSchema = 1

    var schema: Int
    /// Increases with every published change, e.g. each Challenge Update.
    var revision: Int
    /// "Robot Game Rulebook", "Challenge Update 02", …
    var source: String
    var published: String

    var matchSeconds: Int
    /// Points for 0…6 precision tokens left on the field.
    var tokenPoints: [Int]
    var counts: Counts
    var points: Points
    var notes: [String]?

    /// Scoring elements per mission, from the rulebook pictures.
    struct Counts: Codable, Hashable {
        var m02Seeds: Int
        var m06Fragments: Int
        var m14Seeds: Int
    }

    struct Points: Codable, Hashable {
        var inspection: Int
        var m01DroneOffMat: Int
        var m01LidarMapFlipped: Int
        var m02Seed: Int
        var m03FlagDown: Int
        var m03RockReturned: Int
        var m04OneLeaf: Int
        var m04SecondLeaf: Int
        var m05Partial: Int
        var m05Complete: Int
        var m06Fragment: Int
        var m07MyceliumExtended: Int
        var m07Connected: Int
        var m08Vine: Int
        var m09PlatformRaised: Int
        var m09CameraDeployed: Int
        var m09SeedOffTree: Int
        var m10Spider: Int
        var m10Snail: Int
        var m11RootCover: Int
        var m12CaneRaised: Int
        var m12SupportTie: Int
        var m13Keystone: Int
        var m14SeedInStation: Int
        var m14SeedTouchingMat: Int
        var m15Canopy: Int
        var m15Skylight: Int
        var m15Hatch: Int
        var m15DockBonus: Int
    }

    static let maxTokens = 6

    // MARK: Current rules

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _current: GameRules = cachedIfNewer ?? bundled

    /// The rules used for scoring. Safe to read from any thread.
    static var current: GameRules {
        lock.lock()
        defer { lock.unlock() }
        return _current
    }

    static func setCurrent(_ rules: GameRules) {
        lock.lock()
        _current = rules
        lock.unlock()
    }

    /// Robot Game Rulebook values, used if the bundled file is missing or invalid.
    static let rulebook = GameRules(
        schema: 1,
        revision: 1,
        source: "Robot Game Rulebook",
        published: "2026-09-13",
        matchSeconds: 150,
        tokenPoints: [0, 10, 15, 25, 35, 50, 50],
        counts: Counts(m02Seeds: 3, m06Fragments: 4, m14Seeds: 3),
        points: Points(
            inspection: 20,
            m01DroneOffMat: 20, m01LidarMapFlipped: 10,
            m02Seed: 10,
            m03FlagDown: 20, m03RockReturned: 10,
            m04OneLeaf: 10, m04SecondLeaf: 20,
            m05Partial: 10, m05Complete: 20,
            m06Fragment: 10,
            m07MyceliumExtended: 20, m07Connected: 10,
            m08Vine: 30,
            m09PlatformRaised: 10, m09CameraDeployed: 10, m09SeedOffTree: 10,
            m10Spider: 10, m10Snail: 10,
            m11RootCover: 20,
            m12CaneRaised: 20, m12SupportTie: 10,
            m13Keystone: 30,
            m14SeedInStation: 5, m14SeedTouchingMat: 5,
            m15Canopy: 10, m15Skylight: 10, m15Hatch: 10, m15DockBonus: 10
        )
    )

    static let bundled: GameRules =
        Bundle.main.url(forResource: "game-rules", withExtension: "json")
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap { try? GameRules.decode($0) }
        ?? rulebook

    static let cacheURL: URL? = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
        .appendingPathComponent("game-rules.json")

    /// A previously downloaded file, if it's valid and newer than the bundled rules.
    static var cachedIfNewer: GameRules? {
        guard let cacheURL,
            let data = try? Data(contentsOf: cacheURL),
            let cached = try? decode(data),
            cached.revision > bundled.revision
        else { return nil }
        return cached
    }

    // MARK: Validation

    enum ValidationError: Error, Equatable {
        case unsupportedSchema(Int)
        case outOfRange(String)
    }

    static func decode(_ data: Data) throws -> GameRules {
        let rules = try JSONDecoder().decode(GameRules.self, from: data)
        try rules.validate()
        return rules
    }

    /// Rejects files that would break scoring, e.g. a typo making a mission worth 2000.
    func validate() throws {
        guard schema == Self.supportedSchema else {
            throw ValidationError.unsupportedSchema(schema)
        }

        func check(_ name: String, _ value: Int, _ range: ClosedRange<Int>) throws {
            guard range.contains(value) else { throw ValidationError.outOfRange(name) }
        }

        try check("matchSeconds", matchSeconds, 30...600)

        guard tokenPoints.count == Self.maxTokens + 1 else {
            throw ValidationError.outOfRange("tokenPoints")
        }
        for (index, value) in tokenPoints.enumerated() {
            try check("tokenPoints[\(index)]", value, 0...100)
        }
        // Keeping more tokens never scores less.
        guard zip(tokenPoints, tokenPoints.dropFirst()).allSatisfy({ $0 <= $1 }) else {
            throw ValidationError.outOfRange("tokenPoints")
        }

        try check("counts.m02Seeds", counts.m02Seeds, 1...12)
        try check("counts.m06Fragments", counts.m06Fragments, 1...12)
        try check("counts.m14Seeds", counts.m14Seeds, 1...12)

        for child in Mirror(reflecting: points).children {
            guard let label = child.label, let value = child.value as? Int else { continue }
            try check("points.\(label)", value, 0...100)
        }
    }
}

// MARK: - Updates

@MainActor
final class GameRulesStore: ObservableObject {
    static let shared = GameRulesStore()

    nonisolated static let defaultURL = URL(
        string: "https://raw.githubusercontent.com/arstanber/bioglow-scorer-ios/main/config/game-rules.json"
    )!

    enum Status: Equatable {
        case idle
        case checking
        case updated(Int)
        case upToDate
        case failed(String)
    }

    @Published private(set) var rules: GameRules = GameRules.current
    @Published private(set) var status: Status = .idle
    @Published private(set) var lastChecked: Date? =
        UserDefaults.standard.object(forKey: "gameRulesLastChecked") as? Date

    private let cacheURL = GameRules.cacheURL

    private init() {}

    @discardableResult
    func apply(_ newRules: GameRules) -> Bool {
        guard newRules.revision > rules.revision else { return false }

        GameRules.setCurrent(newRules)
        rules = newRules
        return true
    }

    /// Downloads, validates and caches the published rules.
    func checkForUpdates(from url: URL = defaultURL) async {
        status = .checking

        do {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let downloaded = try GameRules.decode(data)
            lastChecked = .now
            UserDefaults.standard.set(lastChecked, forKey: "gameRulesLastChecked")

            if downloaded.revision > rules.revision {
                try? FileManager.default.createDirectory(
                    at: cacheURL!.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try? data.write(to: cacheURL!, options: .atomic)
                apply(downloaded)
                status = .updated(downloaded.revision)
            } else {
                status = .upToDate
            }
        } catch let error as GameRules.ValidationError {
            status = .failed("The published rules file is invalid (\(error)).")
        } catch {
            status = .failed("Couldn't check for rule updates. You're offline or the file isn't published yet.")
        }
    }

    /// Goes back to the rules shipped with the app.
    func resetToBundled() {
        if let cacheURL {
            try? FileManager.default.removeItem(at: cacheURL)
        }
        GameRules.setCurrent(GameRules.bundled)
        rules = GameRules.bundled
        status = .idle
    }
}
