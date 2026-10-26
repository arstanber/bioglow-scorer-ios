//
//  MatchCardExportTests.swift
//  BIOGLOWTests
//

import Foundation
import Testing
import UIKit
@testable import BIOGLOW

@Suite("Shareable match card")
@MainActor
struct MatchCardExportTests {
    @Test(arguments: MatchCardFormat.allCases)
    func rendersAtTwiceTheFormatSize(_ format: MatchCardFormat) async throws {
        let card = MatchCardImage(
            scores: .completed,
            teamNumber: "39112",
            round: .round1,
            timestamp: Date(timeIntervalSince1970: 1_000_000),
            format: format
        )

        let data = try await card.pngData()
        let image = try #require(UIImage(data: data))

        #expect(image.size.width * image.scale == format.size.width * 2)
        #expect(image.size.height * image.scale == format.size.height * 2)
    }
}
