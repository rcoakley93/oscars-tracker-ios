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
    /// "4 of 6 in Movies LLC have seen it."
    let groupSeen: (_ seen: Int, _ members: Int, _ group: String) -> String
    /// After the lock: "62% of Movies LLC picked Hamnet."
    let groupPicked: (_ percent: Int, _ group: String, _ nominee: String) -> String

    // Group comparison (Films) and the board
    /// "2nd of 6 in Movies LLC": a fact, the same in both voices.
    let compareRank: (_ rank: Int, _ size: Int, _ group: String) -> String
    /// You're `films` behind `name`, the person one place above you.
    let compareGap: (_ films: Int, _ name: String) -> String
    let compareTied: (_ name: String) -> String
    /// `name` is `films` behind you, the person one place below.
    let compareChaser: (_ films: Int, _ name: String) -> String
    let boardLeader: String

    // Ballot
    let ballotProgress: (_ picked: Int, _ total: Int) -> String
    /// Under the title while categories are left to pick.
    let ballotIntro: (_ left: Int) -> String
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
    /// The reschedule bar: past days' films not yet watched.
    let planReschedule: (_ films: Int) -> String
    let planNothing: String
    /// After Fill my plan.
    let planFillDone: (_ films: Int, _ days: Int) -> String
    let planFillNothing: String
    /// What can I watch: the best fit, with its runtime already formatted.
    let planFit: (_ title: String, _ runtime: String) -> String
    let planNoFit: String

    // Groups and boards
    let groupsEmpty: Empty
    /// After joining a group.
    let groupsJoined: (_ group: String) -> String
    /// A group with only you in it.
    let boardAlone: String
    let boardEmpty: String
    /// The Predictions tab before the ballot locks.
    let boardPredictionsLocked: String
    /// You're `points` behind `name` on predictions.
    let scoreGap: (_ points: Int, _ name: String) -> String

    // Hero (P6-06): the line under the number follows the season.
    /// Before nominations: the shortlist teaser; `date` ("Jan 21") when known.
    let heroTeaser: (_ films: Int, _ date: String?) -> String
    /// "38 films, 33 days."
    let heroSeason: (_ days: Int, _ filmsLeft: Int) -> String
    /// The last seven days: a push to finish.
    let heroFinalWeek: (_ days: Int, _ filmsLeft: Int) -> String
    /// `left` is already formatted ("3 hours").
    let heroLockDay: (_ left: String) -> String
    /// Locked, waiting for the show; 0 days is the day itself.
    let heroLocked: (_ days: Int) -> String
    /// The show is on: winners announced so far.
    let heroLive: (_ announced: Int, _ total: Int) -> String
    let heroFollow: String
    /// After the show; `isFinal` once every winner is in.
    let heroAfter: (_ isFinal: Bool) -> String

    // Season ticker (screens.md, section 2)
    let tickerSeason: (_ days: Int, _ filmsLeft: Int) -> String
    /// The last seven days.
    let tickerFinalWeek: (_ days: Int, _ filmsLeft: Int) -> String
    /// `left` is already formatted ("3 hours", "40 minutes").
    let tickerLockDay: (_ left: String) -> String
    /// Before nominations; the date ("Jan 21") when it's known.
    let tickerBeforeNominations: (_ date: String?) -> String
    let tickerLive: String
    /// Live mode (P6-02): how many envelopes are open, of how many.
    let tickerLiveProgress: (_ done: Int, _ total: Int) -> String
    /// The live board's line for a category you didn't pick.
    let liveNoPick: String
    /// Results (P6-10): how many of the announced winners you called. The
    /// same figures in both voices; `isFinal` once every winner is in.
    let callTally: (_ correct: Int, _ announced: Int, _ isFinal: Bool) -> String
    /// The recap's eyebrow above your score.
    let recapEyebrow: (_ isFinal: Bool) -> String
    /// Offline: the screens show the last good copy; `waiting` changes will send.
    let tickerOffline: (_ waiting: Int) -> String
    /// After the show: your final place on a board.
    let tickerAfter: (_ rank: Int, _ size: Int, _ board: String) -> String

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

    /// The invite's subject line: a fact, the same in both voices.
    nonisolated static let inviteSubject = "Join my Oscars pool"

    /// "1 point", "3 points".
    nonisolated static func pointCount(_ points: Int) -> String {
        points == 1 ? "1 point" : "\(points) points"
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
        groupSeen: { seen, members, group in "\(seen) of \(members) in \(group) have seen it." },
        groupPicked: { percent, group, nominee in "\(percent)% of \(group) picked \(nominee)." },
        compareRank: rankLine,
        compareGap: { films, name in "You're \(filmCount(films)) behind \(name)." },
        compareTied: { name in "You're tied with \(name)." },
        compareChaser: { films, name in "\(name) is \(filmCount(films)) behind you." },
        boardLeader: "You're in first place.",
        ballotProgress: { picked, total in "\(picked) of \(total) categories picked" },
        ballotIntro: { left in
            "Pick a winner in each category before the ballot locks. \(left) \(left == 1 ? "category" : "categories") left."
        },
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
        planReschedule: { films in "\(filmCount(films)) to reschedule." },
        planNothing: "Nothing planned",
        planFillDone: { films, days in "Planned \(filmCount(films)) over \(Copy.days(days))." },
        planFillNothing: "Every unwatched film is already planned.",
        planFit: { title, runtime in "\(title) (\(runtime)) fits your time." },
        planNoFit: "Nothing fits that time. Try a longer one.",
        groupsEmpty: Empty(title: "You're not in a group yet.", body: "Create a group, or join one with an invite code."),
        groupsJoined: { group in "Joined \(group)." },
        boardAlone: "No other members yet.",
        boardEmpty: "No one is on the board yet.",
        boardPredictionsLocked: "Predictions open when the ballot locks.",
        scoreGap: { points, name in "You're \(pointCount(points)) behind \(name)." },
        heroTeaser: { films, date in
            "\(Copy.filmCount(films)) on the shortlist" + (date.map { " · Nominations announced \($0)." } ?? ".")
        },
        heroSeason: { days, left in
            left == 0 ? "All films watched · \(Copy.days(days)) to the ceremony." : "\(Copy.filmCount(left)) left · \(Copy.days(days)) to the ceremony."
        },
        heroFinalWeek: { days, left in
            left == 0 ? "Final week · All films watched." : "Final week · \(Copy.filmCount(left)) left in \(Copy.days(days))."
        },
        heroLockDay: { left in "Ballot locks in \(left)." },
        heroLocked: { days in days == 0 ? "The ceremony is today." : "Ballot locked · \(Copy.days(days)) to the ceremony." },
        heroLive: { announced, total in "\(announced) of \(total) winners announced." },
        heroFollow: "Follow the ceremony",
        heroAfter: { isFinal in isFinal ? "Your final score." : "Your score so far." },
        tickerSeason: classicCountdown,
        tickerFinalWeek: classicCountdown,
        tickerLockDay: { left in "Ballot locks in \(left)." },
        tickerBeforeNominations: { date in date.map { "Nominations announced \($0)." } ?? "Nominations are coming." },
        tickerLive: "LIVE · Winners as they're announced",
        tickerLiveProgress: { done, total in "LIVE · \(done) of \(total) announced" },
        liveNoPick: "No pick",
        callTally: { correct, announced, isFinal in
            "You called \(correct) of \(announced)" + (isFinal ? "." : " so far.")
        },
        recapEyebrow: { isFinal in isFinal ? "The results" : "The results so far" },
        tickerOffline: { waiting in
            "Offline · showing your last copy" + (waiting > 0 ? " · \(waiting) to send" : "")
        },
        tickerAfter: { rank, size, board in "Final: \(rankLine(rank, size, board))" },
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
        groupSeen: { seen, members, group in
            switch seen {
            case 0: "0 of \(members) in \(group) have seen it. Be the trailblazer."
            case members: "\(seen) of \(members) in \(group) have seen it. Full house."
            default: "\(seen) of \(members) in \(group) have seen it. Peer pressure, but make it cinema."
            }
        },
        groupPicked: { percent, group, nominee in
            percent == 100
                ? "All of \(group) picked \(nominee). Groupthink, or genius."
                : "\(percent)% of \(group) picked \(nominee)."
        },
        compareRank: rankLine,
        compareGap: { films, name in
            films <= 2
                ? "\(filmCount(films)) behind \(name). One double feature and that crown is yours."
                : "\(filmCount(films)) behind \(name). Clear your weekend."
        },
        compareTied: { name in "Dead level with \(name). Someone blinks first." },
        compareChaser: { films, name in
            films == 1
                ? "\(name) is \(filmCount(films)) back. Don't look round."
                : "\(name) is \(filmCount(films)) back. Comfortable, not safe."
        },
        boardLeader: "Top of the board. Act humble.",
        ballotProgress: { picked, total in "\(picked) of \(total) categories picked" },
        ballotIntro: { left in
            left == 1
                ? "One to go. Don't leave a free point on the table."
                : "\(left) to go. Every blank is a free point for your rivals."
        },
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
        planReschedule: { films in
            films == 1 ? "1 film slipped. Happens to the best of us." : "\(films) films slipped. Happens to the best of us."
        },
        planNothing: "Nothing planned. The couch is free.",
        planFillDone: { films, days in
            "Spread \(filmCount(films)) over \(days == 1 ? "1 night" : "\(days) nights"). You're welcome."
        },
        planFillNothing: "Every film already has a date. Look at you.",
        planFit: { title, runtime in "\(runtime) fits. \(title), then bed." },
        planNoFit: "Nothing that short is left. Try a longer slot.",
        groupsEmpty: Empty(title: "No group yet.", body: "Start one and lord over it, or join one with an invite code."),
        groupsJoined: { _ in "You're in. Seats are limited, apparently." },
        boardAlone: "Just you. Fill the seats: share the invite.",
        boardEmpty: "The red carpet's empty. Be the first to arrive.",
        boardPredictionsLocked: "Ballots stay sealed until the lock. No peeking.",
        scoreGap: { points, name in "\(pointCount(points)) behind \(name). It's not over till the last envelope." },
        heroTeaser: { films, date in
            "\(Copy.filmCount(films)) on the shortlist. " + (date.map { "Nominations \($0). Get a head start." } ?? "Get a head start.")
        },
        heroSeason: { days, left in
            left == 0 ? "Every film watched, \(Copy.days(days)) early. Smug is allowed."
                : "\(Copy.filmCount(left)). \(Copy.days(days)). Do the math, or don't."
        },
        heroFinalWeek: { days, left in
            left == 0 ? "Every film watched. Use the week to rehearse your face." :
                days <= 1 ? "Tomorrow night. \(Copy.filmCount(left)) to go. Iron something."
                : "\(Copy.days(days)), \(Copy.filmCount(left)). Time to become a morning person."
        },
        heroLockDay: { left in "Pens down in \(left). Last call for your ballot." },
        heroLocked: { days in days == 0 ? "Tonight's the night. Ballot sealed." : "Ballot sealed. \(Copy.days(days)) to go. Watch something." },
        heroLive: { announced, total in "\(announced) of \(total) envelopes opened. Breathe." },
        heroFollow: "Follow the ceremony",
        heroAfter: { isFinal in isFinal ? "Final score. No appeals." : "Score so far. The envelopes aren't done." },
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
        tickerBeforeNominations: { date in "Shortlists are in. Nominations \(date ?? "soon")." },
        tickerLive: "LIVE · The envelopes are open. Breathe.",
        tickerLiveProgress: { done, total in
            done == 0 ? "LIVE · Envelopes sealed. Breathe." : "LIVE · \(done) of \(total) envelopes open"
        },
        liveNoPick: "You sat this one out",
        callTally: { correct, announced, isFinal in
            let count = "\(correct) of \(announced)"
            if announced == 0 { return "Nothing called yet." }
            if !isFinal { return correct == announced ? "\(count) called. Perfect so far." : "\(count) called so far." }
            if correct == announced { return "\(count). A perfect night. Frame it." }
            if correct * 3 >= announced * 2 { return "\(count) called. The Academy owes you a thank-you note." }
            if correct * 2 >= announced { return "\(count) called. Respectable. Smug, even." }
            return "\(count) called. The Academy zigged. Next year, you zig."
        },
        recapEyebrow: { isFinal in isFinal ? "And that's a wrap" : "The envelopes so far" },
        tickerOffline: { waiting in
            waiting > 0
                ? "Offline. \(waiting == 1 ? "1 change" : "\(waiting) changes") will send when you're back."
                : "Offline. Here's your last copy."
        },
        tickerAfter: { rank, size, board in
            "Final: \(rankLine(rank, size, board)). " + (rank == 1 ? "Take a bow." : "Gracious in defeat?")
        },
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
