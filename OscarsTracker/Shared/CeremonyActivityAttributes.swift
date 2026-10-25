import ActivityKit
import Foundation

/// The ceremony-night Live Activity (P6-03), shared by the app, which starts
/// and updates it, and the widget extension, which draws it.
///
/// `send-push` builds the same JSON for push-to-start and for updates, so the
/// property names here are the keys it writes (camelCase, Swift's defaults).
/// Rename one and the server's must change with it.
nonisolated struct CeremonyActivityAttributes: ActivityAttributes, Sendable {
    /// What changes as winners are announced.
    struct ContentState: Codable, Hashable, Sendable {
        /// The latest category with a winner; nil before the first.
        var category: String?
        /// Its winner (or winners, in a tie): the person in acting
        /// categories, else the film.
        var winner: String?
        /// The film, when the winner is a person.
        var detail: String?
        /// Whether your pick in that category was right; nil with no pick.
        var outcome: Outcome?
        /// Categories with a winner, of `total`.
        var decided: Int
        var total: Int
        /// Your score on the global board.
        var score: Int
        /// Your place on the global board, of `players`; nil until you're on it.
        var rank: Int?
        var players: Int?

        var isFinished: Bool { total > 0 && decided >= total }
    }

    nonisolated enum Outcome: String, Codable, Hashable, Sendable {
        case correct, wrong
    }

    let ceremonyID: Int
    /// "99th Academy Awards".
    let ceremonyName: String
    /// `Voice`'s raw value when it started ("host" or "classic").
    let voice: String
}

// MARK: - Copy

/// The Live Activity's lines in both voices. The extension can't read the
/// app's `Copy` (it has its own process and defaults), so the activity
/// carries the voice it started with.
nonisolated struct LiveActivityCopy: Sendable {
    let isHost: Bool

    init(voice: String) {
        isHost = voice != "classic"
    }

    /// The compact trailing figure, "12/23". Short: the iPhone Duo's outer
    /// display has a narrower island.
    static func progress(_ state: CeremonyActivityAttributes.ContentState) -> String {
        "\(state.decided)/\(state.total)"
    }

    func outcome(_ outcome: CeremonyActivityAttributes.Outcome?) -> String? {
        switch outcome {
        case .correct: isHost ? "You called it. Take a bow." : "You called it"
        case .wrong: isHost ? "Not this time. Chin up." : "Not this time"
        case nil: nil
        }
    }

    /// Before the first envelope.
    var waiting: String {
        isHost ? "The envelopes are sealed. For now." : "Waiting for the first winner"
    }

    func progressLine(_ state: CeremonyActivityAttributes.ContentState) -> String {
        if state.isFinished { return isHost ? "That's a wrap" : "All winners announced" }
        return "\(state.decided) of \(state.total) announced"
    }

    func score(_ score: Int) -> String {
        score == 1 ? "1 point" : "\(score) points"
    }

    /// "3rd of 212"; nil until you're on the board.
    func rank(_ state: CeremonyActivityAttributes.ContentState) -> String? {
        guard let rank = state.rank else { return nil }
        let place = OrdinalStyle().format(rank)
        guard let players = state.players else { return place }
        return "\(place) of \(players)"
    }
}

/// "1st", "2nd", "23rd": English, like the rest of the app's copy.
nonisolated struct OrdinalStyle: FormatStyle {
    func format(_ value: Int) -> String {
        let suffix = switch value % 100 {
        case 11, 12, 13: "th"
        default:
            switch value % 10 {
            case 1: "st"
            case 2: "nd"
            case 3: "rd"
            default: "th"
            }
        }
        return "\(value)\(suffix)"
    }
}

extension CeremonyActivityAttributes {
    /// For previews and tests.
    static let preview = CeremonyActivityAttributes(ceremonyID: 99, ceremonyName: "99th Academy Awards", voice: "host")
}

extension CeremonyActivityAttributes.ContentState {
    static let previewWaiting = Self(decided: 0, total: 23, score: 0)
    static let previewCalled = Self(category: "Actress in a Leading Role", winner: "Jessie Buckley", detail: "Hamnet",
                                    outcome: .correct, decided: 12, total: 23, score: 9, rank: 3, players: 212)
    static let previewMissed = Self(category: "Cinematography", winner: "Sinners", outcome: .wrong,
                                    decided: 13, total: 23, score: 9, rank: 5, players: 212)
    static let previewFinal = Self(category: "Best Picture", winner: "One Battle After Another", outcome: .correct,
                                   decided: 23, total: 23, score: 17, rank: 2, players: 212)
}
