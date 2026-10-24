import Foundation
import SwiftUI

/// The two voices (docs/design/voice.md in the backend repo). Classic says it
/// straight; the Host says the same thing with a wink. Both carry the same
/// facts. Errors that cost the user something live in `AppError`, written
/// once, straight.
enum Voice: String, CaseIterable, Identifiable {
    case host, classic
    var id: String { rawValue }

    /// The `@AppStorage` key for the setting (Profile → Voice).
    static let storageKey = "voice"
}

/// Every line that has two voices. Add a moment here first; both `host` and
/// `classic` must then give it a line, or the app won't compile.
struct Copy {
    struct Empty {
        let title: String
        let body: String
    }

    // Progress
    let progressSummary: (_ watched: Int, _ total: Int) -> String
    let pace: (_ perDay: String, _ deadline: String) -> String
    let paceCaption: (_ deadline: String) -> String
    let allWatched: String

    // Films
    let toWatchHeading: String
    let watchedHeading: String
    let markWatched: String
    let watched: String
    let watchHint: String
    let noProviders: String
    /// Before nominations; the date ("Jan 21") once the season facts give it.
    let filmsPreseason: (_ date: String?) -> Empty
    let searchEmpty: String

    // Group comparison (Films) and the board
    /// "2nd of 6 in Movies LLC": a fact, the same in both voices.
    let compareRank: (_ rank: Int, _ size: Int, _ group: String) -> String
    /// You're `films` behind `name`, the person one place above you.
    let compareGap: (_ films: Int, _ name: String) -> String
    let compareTied: (_ name: String) -> String
    let boardLeader: String

    // Ballot
    let ballotProgress: (_ picked: Int, _ total: Int) -> String
    let ballotComplete: (_ total: Int) -> String
    /// After a pick; the seed (the nomination id) keeps the Host's line steady.
    let pickSaved: (_ seed: Int) -> String
    let lockLabel: String
    let locked: String
    let ballotEmpty: Empty

    // Results
    let correct: String
    let wrong: String

    // Watch plan
    let planEmpty: Empty
    let markedWatched: String
    let rescheduled: String
    let removed: String

    // Groups and boards
    let groupsEmpty: Empty
    let groupBoardEmpty: String
    let boardEmpty: String

    // Season ticker (screens.md, section 2)
    let tickerSeason: (_ days: Int, _ filmsLeft: Int) -> String
    /// The last seven days.
    let tickerFinalWeek: (_ days: Int, _ filmsLeft: Int) -> String
    /// `left` is already formatted ("3 hours", "40 minutes").
    let tickerLockDay: (_ left: String) -> String

    // The setting itself
    let label: String
    let sample: String
}

extension Copy {
    /// "1 day", "33 days".
    nonisolated static func days(_ days: Int) -> String {
        days == 1 ? "1 day" : "\(days) days"
    }

    /// "1 film", "2 films".
    nonisolated static func filmCount(_ films: Int) -> String {
        films == 1 ? "1 film" : "\(films) films"
    }

    /// "2nd of 6 in Movies LLC".
    nonisolated static func rankLine(_ rank: Int, _ size: Int, _ group: String) -> String {
        let ordinal = NumberFormatter()
        ordinal.numberStyle = .ordinal
        return "\(ordinal.string(from: rank as NSNumber) ?? "\(rank)") of \(size) in \(group)"
    }

    static func `for`(_ voice: Voice) -> Copy {
        voice == .host ? host : classic
    }

    static let classic = Copy(
        progressSummary: { watched, total in "\(watched) of \(total) films watched." },
        pace: { perDay, deadline in "Watch \(perDay) films a day to finish by \(deadline)." },
        paceCaption: { deadline in "to finish by \(deadline)" },
        allWatched: "All nominated films watched.",
        toWatchHeading: "Still to watch",
        watchedHeading: "Watched",
        markWatched: "Mark as watched",
        watched: "Watched",
        watchHint: "Adds it to your watched films.",
        noProviders: "No streaming information yet. JustWatch may know more.",
        filmsPreseason: { date in
            Empty(title: date.map { "The nominees arrive \($0)" } ?? "No nominees yet",
                  body: "The films appear here when nominations are announced.")
        },
        searchEmpty: "Search films and nominees.",
        compareRank: rankLine,
        compareGap: { films, name in "You're \(filmCount(films)) behind \(name)." },
        compareTied: { name in "You're tied with \(name)." },
        boardLeader: "You're in first place.",
        ballotProgress: { picked, total in "\(picked) of \(total) categories picked" },
        ballotComplete: { total in "All \(total) categories picked." },
        pickSaved: { _ in "Pick saved." },
        lockLabel: "Predictions lock at",
        locked: "The ballot is locked. Predictions are final.",
        ballotEmpty: Empty(title: "No categories yet", body: "Check back when nominations are announced."),
        correct: "Correct.",
        wrong: "Not this time.",
        planEmpty: Empty(title: "No films planned yet", body: "Tap + to add films to your watch plan."),
        markedWatched: "Marked as watched.",
        rescheduled: "Rescheduled.",
        removed: "Removed from your plan.",
        groupsEmpty: Empty(title: "No groups yet", body: "Create a group, or join one with an invite code, to compete with friends."),
        groupBoardEmpty: "No members yet. Share the invite code to add people.",
        boardEmpty: "No one is on the board yet.",
        tickerSeason: classicCountdown,
        tickerFinalWeek: classicCountdown,
        tickerLockDay: { left in "Ballot locks in \(left)." },
        label: "Classic",
        sample: "12 of 50 films watched."
    )

    /// "33 days to the ceremony · 38 films left", the same in the final week.
    private nonisolated static func classicCountdown(_ days: Int, _ left: Int) -> String {
        "\(Copy.days(days)) to the ceremony · " + (left == 0 ? "All films watched" : "\(left) \(left == 1 ? "film" : "films") left")
    }

    private static let hostPickLines = [
        "Noted. The envelope will decide.",
        "Locked in. Well, until the ballot locks.",
        "A choice was made. A bold one, possibly.",
        "The Host approves. Probably.",
    ]

    static let host = Copy(
        progressSummary: { watched, total in
            watched == 0
                ? "0 of \(total). Every marathon starts on the couch."
                : "\(watched) down, \(total - watched) to go. The Academy watched all of these. Allegedly."
        },
        pace: { perDay, deadline in
            (Double(perDay) ?? 2) <= 1
                ? "One a day keeps the FOMO away, and gets you there by \(deadline)."
                : "\(perDay) films a day gets you there by \(deadline). Pace yourself."
        },
        paceCaption: { deadline in "to finish by \(deadline). Popcorn is a food group now." },
        allWatched: "Every nominee, watched. You've out-watched the Academy.",
        toWatchHeading: "Still to watch",
        watchedHeading: "Your ticket stubs",
        markWatched: "Mark as watched",
        watched: "Watched",
        watchHint: "Tear the ticket. You know you want to.",
        noProviders: "Not streaming anywhere we know of. JustWatch might have the scoop.",
        filmsPreseason: { date in
            Empty(title: date.map { "Nominations land \($0)" } ?? "The envelopes aren't printed yet",
                  body: "Until then, the shortlists. Check back on nominations day.")
        },
        searchEmpty: "Search the nominees. All of them. Even the shorts.",
        compareRank: rankLine,
        compareGap: { films, name in
            films <= 2
                ? "\(filmCount(films)) behind \(name). One double feature and that crown is yours."
                : "\(filmCount(films)) behind \(name). Clear your weekend."
        },
        compareTied: { name in "Dead level with \(name). Someone blinks first." },
        boardLeader: "Top of the board. Act humble.",
        ballotProgress: { picked, total in "\(picked) of \(total) categories picked" },
        ballotComplete: { _ in "Every category, locked in. Now we wait." },
        pickSaved: { seed in hostPickLines[abs(seed) % hostPickLines.count] },
        lockLabel: "Pens down at",
        locked: "Pens down. Your picks are final.",
        ballotEmpty: Empty(title: "The envelopes aren't printed yet", body: "Check back on nominations day. We'll save you a seat."),
        correct: "Called it.",
        wrong: "The Academy has spoken. Wrongly, obviously.",
        planEmpty: Empty(title: "No plans? Bold strategy for awards season.", body: "Tap + and pencil in a film or two."),
        markedWatched: "Another one down.",
        rescheduled: "Moved. Life happens.",
        removed: "Cut in the edit.",
        groupsEmpty: Empty(title: "Flying solo?", body: "Start a group, or join one with an invite code. Awards season is better with rivals."),
        groupBoardEmpty: "Nobody here yet. Share the invite code and fill the seats.",
        boardEmpty: "The red carpet's empty. Be the first to arrive.",
        tickerSeason: { days, left in
            left == 0
                ? "\(Copy.days(days)). Every film watched. Smug is allowed."
                : "\(Copy.days(days)). \(left) \(left == 1 ? "film" : "films"). Do the math, or don't."
        },
        tickerFinalWeek: { days, _ in
            switch days {
            case 7: "One week. Time to become a morning person."
            case 1: "Tomorrow night. Iron something."
            default: "\(days) days. Time to become a morning person."
            }
        },
        tickerLockDay: { left in "Pens down in \(left)." },
        label: "Host",
        sample: "12 down, 38 to go. The Academy watched all of these. Allegedly."
    )
}

private struct CopyKey: EnvironmentKey {
    static let defaultValue = Copy.host
}

extension EnvironmentValues {
    /// The copy for the viewer's voice. Set once at the root from the
    /// `Voice.storageKey` setting; read with `@Environment(\.copy)`.
    var copy: Copy {
        get { self[CopyKey.self] }
        set { self[CopyKey.self] = newValue }
    }
}
