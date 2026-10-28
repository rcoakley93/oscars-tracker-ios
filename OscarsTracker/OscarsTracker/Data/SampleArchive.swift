import Foundation

/// The sample past season (P12-06): the 98th, from the sample films, with a
/// full ballot, two groups and two badges. `noPicks` and `noGroup` are the
/// other preview states.
extension SampleData {
    private typealias Nominee = SeasonArchive.Nominee

    private static func nominee(_ id: Int, _ film: Int, _ person: String? = nil) -> Nominee {
        let movie = movies[film - 1]
        return Nominee(nominationId: id, movieId: movie.id, title: movie.title, posterUrl: movie.posterUrl,
                       releaseYear: movie.releaseYear, detailText: person)
    }

    private static func category(_ id: Int, _ name: String, _ mode: SeasonArchive.DisplayMode = .film,
                                 pick: Nominee?, winner: Nominee?) -> SeasonArchive.Category {
        SeasonArchive.Category(id: id, name: name, displayMode: mode, pointsValue: 1, pick: pick,
                               winners: winner.map { [$0] } ?? [],
                               isCorrect: pick.flatMap { pick in winner.map { $0 == pick } })
    }

    private static let ceremonyAt98 = Date(timeIntervalSince1970: 1_773_014_400)

    static let archive98 = SeasonArchive(
        ceremony: .init(id: 1, number: 98, name: "98th Academy Awards", ceremonyAt: ceremonyAt98, filmCount: 10),
        ballot: [
            category(11, "Best Picture", pick: nominee(1101, 4), winner: nominee(1101, 4)),
            category(12, "Directing", pick: nominee(1201, 1), winner: nominee(1202, 4)),
            category(13, "Actress in a Leading Role", .person,
                     pick: nominee(1301, 1, "Jessie Buckley"), winner: nominee(1301, 1, "Jessie Buckley")),
            category(14, "Actor in a Leading Role", .person,
                     pick: nominee(1401, 9, "Timothée Chalamet"), winner: nominee(1402, 5, "Michael B. Jordan")),
            category(15, "Animated Feature Film", pick: nominee(1501, 3), winner: nominee(1501, 3)),
            category(16, "International Feature Film", pick: nil, winner: nominee(1601, 6)),
        ],
        watched: [1, 4, 3, 5, 6, 9].map { id in
            let movie = movies[id - 1]
            return SeasonArchive.Film(movieId: movie.id, title: movie.title, posterUrl: movie.posterUrl,
                                      releaseYear: movie.releaseYear, watchedAt: ceremonyAt98.addingTimeInterval(-Double(id) * 86_400))
        },
        boards: [
            .init(groupId: nil, groupName: nil, rank: 3, players: 212, score: 4, scoring: .traditional,
                  correctCount: 4, points: 4, watchedCount: 6),
            .init(groupId: 2, groupName: "Family pool", rank: 2, players: 6, score: 4, scoring: .traditional,
                  correctCount: 4, points: 4, watchedCount: 6),
            .init(groupId: 1, groupName: "Movies LLC", rank: 1, players: 8, score: 11, scoring: .weighted,
                  correctCount: 4, points: 11, watchedCount: 6),
        ],
        badges: [
            UserBadge(badgeKey: "films_watched", shelf: "watching", sortOrder: 4, ceremonyId: 1, ceremonyNumber: 98,
                      tier: 1, tierName: "bronze", earnedAt: ceremonyAt98),
            UserBadge(badgeKey: "top_billing", shelf: "groups", sortOrder: 12, ceremonyId: 1, ceremonyNumber: 98,
                      tier: 3, tierName: "gold", earnedAt: ceremonyAt98),
        ]
    )

    /// Watched a few films, never filled a ballot.
    static let archiveNoPicks = SeasonArchive(
        ceremony: archive98.ceremony,
        ballot: archive98.ballot.map {
            SeasonArchive.Category(id: $0.id, name: $0.name, displayMode: $0.displayMode, pointsValue: $0.pointsValue,
                                   pick: nil, winners: $0.winners, isCorrect: nil)
        },
        watched: Array(archive98.watched.prefix(2)),
        boards: [.init(groupId: nil, groupName: nil, rank: 140, players: 212, score: 0, scoring: .traditional,
                       correctCount: 0, points: 0, watchedCount: 2)],
        badges: []
    )

    /// A full ballot, played on the global board alone.
    static let archiveNoGroup = SeasonArchive(
        ceremony: archive98.ceremony,
        ballot: archive98.ballot,
        watched: archive98.watched,
        boards: Array(archive98.boards.prefix(1)),
        badges: []
    )
}
