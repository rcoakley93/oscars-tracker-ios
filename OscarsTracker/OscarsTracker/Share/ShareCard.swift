import Foundation

/// What a share card says (P6-08): your ballot before the lock, or your score
/// and rank once winners are in. Built from the stores' data, so it can be
/// tested without a view.
nonisolated struct ShareCard: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// Your picks, before winners are in.
        case ballot
        /// Your score and rank, after.
        case results
    }

    struct Line: Identifiable, Equatable, Sendable {
        let id: Int
        let category: String
        /// The person for acting categories, else the film; nil with no pick.
        let pick: String?
        /// The film under a person's name.
        let film: String?
        let posterURL: String?
        let points: Int
        /// Nil until the category's winner is set, or with no pick.
        let isCorrect: Bool?
    }

    let kind: Kind
    let seasonName: String
    let username: String?
    let lines: [Line]
    let correctCount: Int
    let score: Int
    /// Your place on the global board by predictions; nil if it isn't loaded.
    let rank: Int?
    let boardSize: Int?

    var pickedCount: Int { lines.count { $0.pick != nil } }
    var totalCount: Int { lines.count }

    /// How many posters the card shows.
    static let posterLimit = 6

    /// The posters of your picks, the highest-value categories first, one per
    /// film, so Best Picture and Director lead.
    var posterURLs: [String] {
        var seen = Set<String>()
        return lines.filter { $0.pick != nil }
            .sorted { $0.points > $1.points }
            .compactMap(\.posterURL)
            .filter { seen.insert($0).inserted }
            .prefix(Self.posterLimit)
            .map { $0 }
    }

    /// "Ballot" or "Final score".
    var title: String { kind == .ballot ? "My ballot" : "My final score" }

    /// "#3 of 1,204".
    var rankText: String? {
        guard let rank, let boardSize else { return nil }
        return "#\(rank) of \(boardSize.formatted())"
    }

    /// Nil when there's nothing to share yet: no ballot, or no picks.
    static func make(categories: [BallotCategory], picks: [Int: Int], seasonName: String, username: String?,
                     standing: LeaderboardStore.Standing?) -> ShareCard? {
        guard !categories.isEmpty, categories.contains(where: { picks[$0.id] != nil }) else { return nil }
        let hasWinners = categories.contains { $0.nominations.contains(where: \.isWinner) }
        let lines = categories.map { category -> Line in
            let nominee = picks[category.id].flatMap { id in category.nominations.first { $0.id == id } }
            let person = nominee?.personName.flatMap { $0.isEmpty ? nil : $0 }
            let winner = category.nominations.first(where: \.isWinner)
            return Line(id: category.id,
                        category: category.name,
                        pick: nominee.map { person ?? $0.movie?.title ?? "Unknown" },
                        film: person == nil ? nil : nominee?.movie?.title,
                        posterURL: nominee?.movie?.posterUrl,
                        points: category.pointsValue,
                        isCorrect: nominee.flatMap { n in winner.map { $0.id == n.id } })
        }
        let correct = lines.filter { $0.isCorrect == true }
        return ShareCard(kind: hasWinners ? .results : .ballot,
                         seasonName: seasonName,
                         username: username,
                         lines: lines,
                         correctCount: correct.count,
                         score: correct.map(\.points).reduce(0, +),
                         rank: standing?.rank,
                         boardSize: standing?.size)
    }
}
