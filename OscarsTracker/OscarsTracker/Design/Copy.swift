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

    // The setting itself
    let label: String
    let sample: String
}

extension Copy {
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
        label: "Classic",
        sample: "12 of 50 films watched."
    )

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
