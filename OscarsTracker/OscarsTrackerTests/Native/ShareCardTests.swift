import Foundation
import Testing
import UIKit
@testable import OscarsTracker

@MainActor
struct ShareCardTests {
    private func film(_ id: Int, _ poster: String? = nil) -> Movie {
        Movie(id: id, title: "Film \(id)", posterUrl: poster, releaseYear: 2026, runtimeMinutes: 100, createdAt: nil)
    }

    private func category(_ id: Int, points: Int, winner: Int? = nil, person: String? = nil) -> BallotCategory {
        BallotCategory(id: id, name: "Category \(id)", pointsValue: points, nominations: (1...2).map { n in
            BallotNominee(id: id * 10 + n, movie: film(id * 10 + n, "https://image.tmdb.org/t/p/original/\(id)\(n).jpg"),
                          personName: person, isWinner: winner == id * 10 + n)
        })
    }

    @Test func nothingToShareWithoutPicks() {
        let card = ShareCard.make(categories: [category(1, points: 5)], picks: [:], seasonName: "99th", username: nil, standing: nil)
        #expect(card == nil)
        #expect(ShareCard.make(categories: [], picks: [:], seasonName: "99th", username: nil, standing: nil) == nil)
    }

    @Test func ballotCardBeforeWinners() throws {
        let card = try #require(ShareCard.make(categories: [category(1, points: 5), category(2, points: 3)], picks: [1: 11],
                                               seasonName: "99th", username: "ana", standing: nil))
        #expect(card.kind == .ballot)
        #expect(card.pickedCount == 1)
        #expect(card.totalCount == 2)
        #expect(card.lines[0].pick == "Film 11")
        #expect(card.lines[1].pick == nil)
        #expect(card.lines[0].isCorrect == nil)
        #expect(card.title == "My ballot")
    }

    @Test func resultsCardScoresWins() throws {
        let categories = [category(1, points: 10, winner: 11), category(2, points: 3, winner: 22), category(3, points: 1, winner: 31)]
        let standing = LeaderboardStore.Standing(rank: 3, size: 1204, position: .first)
        let card = try #require(ShareCard.make(categories: categories, picks: [1: 11, 2: 21], seasonName: "99th", username: nil, standing: standing))
        #expect(card.kind == .results)
        #expect(card.correctCount == 1)
        #expect(card.score == 10)
        #expect(card.lines.map(\.isCorrect) == [true, false, nil])
        #expect(card.rank == 3)
        #expect(card.rankText?.hasPrefix("#3 of 1") == true)
        #expect(card.title == "My final score")
    }

    @Test func actingCategoriesLeadWithThePerson() throws {
        let card = try #require(ShareCard.make(categories: [category(1, points: 5, person: "Jessie Buckley")], picks: [1: 11],
                                               seasonName: "99th", username: nil, standing: nil))
        #expect(card.lines[0].pick == "Jessie Buckley")
        #expect(card.lines[0].film == "Film 11")
    }

    @Test func postersAreDistinctAndLedByPoints() throws {
        let categories = (1...9).map { category($0, points: $0) }
        var picks = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.id * 10 + 1) })
        picks[1] = 91 // same film as category 9
        let card = try #require(ShareCard.make(categories: categories, picks: picks, seasonName: "99th", username: nil, standing: nil))
        #expect(card.posterURLs.count == ShareCard.posterLimit)
        #expect(card.posterURLs.first == "https://image.tmdb.org/t/p/original/91.jpg")
    }

    @Test func rendersA1080By1920Image() throws {
        for results in [false, true] {
            let image = try #require(ShareCardRenderer.render(.preview(results: results), posters: [:]))
            #expect(image.size.width * image.scale == 1080)
            #expect(image.size.height * image.scale == 1920)
            if let path = ProcessInfo.processInfo.environment["SHARE_CARD_DUMP"] {
                try image.pngData()?.write(to: URL(fileURLWithPath: "\(path)-\(results ? "results" : "ballot").png"))
            }
        }
    }
}
