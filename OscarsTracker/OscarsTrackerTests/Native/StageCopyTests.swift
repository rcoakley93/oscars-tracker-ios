import Foundation
import Supabase
import Testing
@testable import OscarsTracker

/// P10-04: every line that names the films reads right at each list stage, in
/// both voices (voice.md, "Stage vocabulary"). P10-03: the moment on the first
/// launch at a new stage.
@MainActor
@Suite("Stage copy and moments")
struct StageCopyTests {
    private let user = SampleDataSource.userID

    /// Every line that names the films, as the app shows it at a stage.
    private func stageLines(_ copy: Copy) -> [String] {
        let preseason = [copy.filmsPreseason(nil), copy.filmsPreseason("Jan 21")]
        return [
            copy.allWatched, copy.searchEmpty, copy.searchPrompt, copy.progressSummary(0, 40), copy.progressSummary(12, 40),
            copy.ballotEmpty.title, copy.ballotEmpty.body, copy.planFillNothing, copy.boardPredictionsLocked,
            copy.heroTeaser(0, "Jan 21"), copy.heroTeaser(12, "Jan 21"), copy.heroTeaser(12, nil),
            copy.tickerBeforeNominations("Jan 21", 12), copy.tickerBeforeNominations(nil, nil), copy.tickerBeforeNominations("Jan 21", 0),
            copy.stageMomentTitle, copy.stageMomentBody(14, 20, 52), copy.stageMomentBody(0, 0, 52),
            copy.stageMomentBody(20, 20, 52), copy.stageMomentBody(0, 20, 52), copy.stageMomentAdded,
        ] + preseason.flatMap { [$0.title, $0.body] }
    }

    /// "Nominee" and "nominated" with the phrases voice.md allows before
    /// nominations taken out: "the likely nominees", "expect to be nominated".
    private func namesNominees(_ line: String) -> Bool {
        let rest = line.lowercased()
            .replacingOccurrences(of: "likely nominee", with: "")
            .replacingOccurrences(of: "expect to be nominated", with: "")
        return rest.contains("nominee") || rest.contains("nominated")
    }

    @Test(arguments: Voice.allCases, ListStage.allCases)
    func everyStageHasEveryLineInBothVoices(voice: Voice, stage: ListStage) {
        let copy = Copy.for(voice, stage: stage)
        #expect(copy.stage == stage)
        for line in stageLines(copy) {
            #expect(!line.trimmingCharacters(in: .whitespaces).isEmpty)
            if voice == .classic { #expect(!line.contains("!"), "Classic has no exclamation marks: \(line)") }
        }
    }

    @Test(arguments: Voice.allCases, [ListStage.predicted, .shortlisted])
    func beforeNominationsTheFilmsAreContendersNeverNominees(voice: Voice, stage: ListStage) {
        for line in stageLines(Copy.for(voice, stage: stage)) {
            #expect(!namesNominees(line), "\(voice) at \(stage): \(line)")
        }
    }

    @Test(arguments: Voice.allCases)
    func fromNominationsDayTheFilmsAreNominees(voice: Voice) {
        let copy = Copy.for(voice, stage: .nominated)
        for line in stageLines(copy) {
            #expect(!line.lowercased().contains("contender"), "\(voice): \(line)")
        }
        #expect(copy.allWatched.lowercased().contains("nomin"))
        #expect(copy.searchEmpty.lowercased().contains("nominee"))
        #expect(copy.searchPrompt == "Films and nominees")
    }

    @Test(arguments: Voice.allCases)
    func theStagesSayDifferentThings(voice: Voice) {
        let lines = ListStage.allCases.map { Copy.for(voice, stage: $0) }
        #expect(Set(lines.map(\.stageMomentTitle)).count == 3)
        #expect(Set(lines.map { $0.heroTeaser(12, "Jan 21") }).count == 3)
        #expect(Set(lines.map { $0.tickerBeforeNominations("Jan 21", 12) }).count == 3)
        #expect(Set(lines.map { $0.ballotEmpty.body }).count >= 2)
    }

    @Test(arguments: Voice.allCases, ListStage.allCases)
    func bothVoicesCarryTheSameNumbers(voice: Voice, stage: ListStage) {
        let copy = Copy.for(voice, stage: stage)
        if stage.showsContenders {
            #expect(copy.heroTeaser(12, "Jan 21").contains("12"))
            #expect(copy.heroTeaser(12, "Jan 21").contains("Jan 21"))
            #expect(copy.tickerBeforeNominations("Jan 21", 12).contains("12"))
            #expect(copy.tickerBeforeNominations("Jan 21", 12).contains("Jan 21"))
        }
        if stage == .predicted {
            #expect(copy.stageMomentBody(0, 0, 40).contains("40"))
        } else {
            let body = copy.stageMomentBody(14, 20, 52)
            #expect(body.contains("14") && body.contains("20"))
            #expect(copy.stageMomentBody(0, 0, 52).contains("52"))
        }
    }

    @Test func theOddsStayABarePercentage() {
        for voice in Voice.allCases {
            for stage in ListStage.allCases {
                _ = Copy.for(voice, stage: stage)
                #expect(Copy.odds(72) == "72%")
            }
        }
    }

    @Test func theNominatedStageKeeps20sLines() {
        #expect(Copy.for(.classic).allWatched == "All nominated films watched.")
        #expect(Copy.host.searchEmpty == "Search the nominees. All of them. Even the shorts.")
        #expect(Copy.for(.classic, stage: .shortlisted).stageMomentBody(14, 20, 52) == "14 of the 20 films you've watched made it.")
        #expect(Copy.for(.host, stage: .shortlisted).stageMomentBody(14, 20, 52) == "14 of your 20 films made it.")
    }

    // MARK: - Overrides (app_config.copy_overrides)

    @Test func aStageOverrideWinsOverThePlainKey() {
        let overrides: CopyOverrides = [
            "stage.moment.title": ["host": "Plain", "classic": "Plain classic"],
            "stage.moment.title.shortlisted": ["host": "Dec 15. The plot thickens."],
        ]
        #expect(Copy.for(.host, stage: .shortlisted, overrides: overrides).stageMomentTitle == "Dec 15. The plot thickens.")
        #expect(Copy.for(.classic, stage: .shortlisted, overrides: overrides).stageMomentTitle == "Plain classic")
        #expect(Copy.for(.host, stage: .nominated, overrides: overrides).stageMomentTitle == "Plain")
    }

    @Test func anOverrideFillsItsValuesOrFallsBack() {
        let overrides: CopyOverrides = [
            "ticker.beforeNominations.predicted": ["classic": "{left} contenders · Nominations {date}"],
            "films.hero.teaser": ["host": "{nonsense} left"],
            "stage.moment.body": ["classic": "{made} of {watched} made it, of {total}."],
        ]
        let classic = Copy.for(.classic, stage: .predicted, overrides: overrides)
        #expect(classic.tickerBeforeNominations("Jan 21", 12) == "12 contenders · Nominations Jan 21")
        // No list yet: the template needs {left}, so the built-in line stays.
        #expect(classic.tickerBeforeNominations("Jan 21", nil) == Copy.for(.classic, stage: .predicted).tickerBeforeNominations("Jan 21", nil))
        #expect(classic.stageMomentBody(3, 4, 12) == "3 of 4 made it, of 12.")
        let host = Copy.for(.host, stage: .predicted, overrides: overrides)
        #expect(host.heroTeaser(12, "Jan 21") == Copy.for(.host, stage: .predicted).heroTeaser(12, "Jan 21"))
    }

    @Test func overridesParseFromAppConfig() throws {
        let parsed = LiveDataSource.copyOverrides([
            "stage.moment.title": .object(["host": .string("Hi"), "classic": .integer(3)]),
            "broken": .string("not an object"),
        ])
        #expect(parsed == ["stage.moment.title": ["host": "Hi"]])
        var config = AppConfig.defaults
        config.copyOverrides = parsed
        let round = try JSONDecoder().decode(AppConfig.self, from: JSONEncoder().encode(config))
        #expect(round.copyOverrides == parsed)
        let old = #"{"minSupportedBuild":0,"featureFlags":{},"runtimeBuckets":[]}"#
        #expect(try JSONDecoder().decode(AppConfig.self, from: Data(old.utf8)).copyOverrides.isEmpty)
    }

    // MARK: - Stage moments (P10-03)

    @Test func aMomentComparesWithTheLastList() {
        let seen = StageMoment.Seen(stage: .predicted, ids: [1, 2, 3, 4])
        let now = StageMoment.Seen(stage: .shortlisted, ids: [2, 3, 5, 6])
        let moment = StageMoment.between(seen, and: now, watchedIDs: [1, 2, 3, 9])
        #expect(moment == StageMoment(stage: .shortlisted, made: 2, watched: 3, total: 4, addedIDs: [5, 6]))
        #expect(StageMoment.between(nil, and: now, watchedIDs: []) == nil)
        #expect(StageMoment.between(now, and: StageMoment.Seen(stage: .shortlisted, ids: [7]), watchedIDs: []) == nil)
    }

    @Test func theFirstLaunchAtANewStageShowsTheMomentOnce() async {
        let data = SampleDataSource()
        data.useListStage(.predicted)
        let model = AppModel(data: data)
        await model.start()
        // The first launch has nothing to compare.
        #expect(model.navigation.sheet == nil)
        #expect(model.stageMoment == nil)
        await model.films.toggleWatched(11, userID: user)

        // Dec 15: only the server changes.
        data.useListStage(.shortlisted)
        await model.foreground()
        #expect(model.navigation.sheet == .stageMoment)
        let moment = model.stageMoment
        #expect(moment?.stage == .shortlisted)
        #expect(moment?.total == model.films.list.count)
        let before = Set(SampleData.contenders(.predicted).map(\.movieId))
        #expect(moment?.watched == model.films.watchedIDs.intersection(before).count)
        #expect(moment?.addedIDs == model.films.list.map(\.id).filter { !before.contains($0) })

        // Seen: the next refresh doesn't show it again.
        model.navigation.sheet = nil
        await model.refresh()
        #expect(model.navigation.sheet == nil)

        // Jan 21: the nominees, with the films you'd watched that made it.
        model.navigation.sheet = nil
        let shortlisted = Set(model.films.list.map(\.id))
        data.useListStage(.nominated)
        await model.foreground()
        #expect(model.navigation.sheet == .stageMoment)
        #expect(model.stageMoment?.stage == .nominated)
        let made = model.films.watchedIDs.intersection(shortlisted).intersection(model.films.list.map(\.id))
        #expect(model.stageMoment?.made == made.count)
    }

    @Test func anOpenSheetHoldsTheMomentForLater() async {
        let data = SampleDataSource()
        data.useListStage(.predicted)
        let model = AppModel(data: data)
        await model.start()
        data.useListStage(.shortlisted)
        model.navigation.sheet = .search
        await model.refresh()
        #expect(model.navigation.sheet == .search)
        model.navigation.sheet = nil
        // A film's detail open from Films (compact width) holds it too.
        model.navigation.isFilmSheetOpen = true
        await model.refresh()
        #expect(model.navigation.sheet == nil)
        model.navigation.isFilmSheetOpen = false
        await model.refresh()
        #expect(model.navigation.sheet == .stageMoment)
        #expect(model.stageMoment?.stage == .shortlisted)
    }

    @Test func signingOutForgetsTheMoment() async {
        let data = SampleDataSource()
        data.useListStage(.predicted)
        let model = AppModel(data: data)
        await model.start()
        data.useListStage(.shortlisted)
        await model.refresh()
        #expect(model.stageMoment != nil)
        await model.signOut()
        #expect(model.stageMoment == nil)
    }

    // MARK: - Films subtitle

    @Test(arguments: [
        (Voice.classic, ListStage.predicted, "Predicted nominees · 99th Academy Awards"),
        (.classic, .shortlisted, "Shortlists and predictions · 99th"),
        (.classic, .nominated, "Nominees · 99th Academy Awards"),
        (.host, .predicted, "Our picks for the 99th"),
        (.host, .shortlisted, "The shortlists, plus our hunches"),
        (.host, .nominated, "The 99th nominees"),
    ])
    func filmsSubtitleFollowsStageAndVoice(voice: Voice, stage: ListStage, line: String) {
        let copy = Copy.for(voice, stage: stage)
        #expect(copy.filmsSubtitle(ceremony: 99, isRehearsal: false) == line)
        #expect(copy.filmsSubtitle(ceremony: 99, isRehearsal: true) == "Rehearsal: " + line)
    }

    @Test func ceremonyNumberComesFromData() {
        #expect(Copy.ordinal(99) == "99th")
        #expect(Copy.ordinal(101) == "101st")
        #expect(Copy.classic.filmsSubtitle(ceremony: 100, isRehearsal: false) == "Nominees · 100th Academy Awards")
    }

    @Test(arguments: Voice.allCases, ListStage.allCases)
    func filmsSubtitleOverrides(voice: Voice, stage: ListStage) {
        let plain: CopyOverrides = ["films.subtitle": [voice.rawValue: "Plain {ordinal}"]]
        #expect(Copy.for(voice, stage: stage, overrides: plain).filmsSubtitle("99th") == "Plain 99th")
        let keyed: CopyOverrides = [
            "films.subtitle": [voice.rawValue: "Plain {ordinal}"],
            "films.subtitle.\(stage.rawValue)": [voice.rawValue: "Staged {ordinal}"],
        ]
        #expect(Copy.for(voice, stage: stage, overrides: keyed).filmsSubtitle("99th") == "Staged 99th")
        // Another stage's key doesn't apply; a template with an unknown value falls back.
        let other = ListStage.allCases.first { $0 != stage }!
        let elsewhere: CopyOverrides = ["films.subtitle.\(other.rawValue)": [voice.rawValue: "Nope"]]
        #expect(Copy.for(voice, stage: stage, overrides: elsewhere).filmsSubtitle("99th") == Copy.for(voice, stage: stage).filmsSubtitle("99th"))
        let broken: CopyOverrides = ["films.subtitle": [voice.rawValue: "{nope}"]]
        #expect(Copy.for(voice, stage: stage, overrides: broken).filmsSubtitle("99th") == Copy.for(voice, stage: stage).filmsSubtitle("99th"))
    }

    @Test(arguments: Voice.allCases)
    func filmsListHintNamesWhatTheListIs(voice: Voice) {
        #expect(Copy.for(voice, stage: .predicted).filmsListHint.lowercased().contains("predicted nominees"))
        let shortlisted = Copy.for(voice, stage: .shortlisted).filmsListHint.lowercased()
        #expect(shortlisted.contains("shortlists") && shortlisted.contains("predictions"))
        #expect(Copy.for(voice, stage: .nominated).filmsListHint.isEmpty)
    }

    @Test func voiceSampleFollowsTheStage() {
        #expect(Copy.for(.classic, stage: .predicted).sample == "12 of 50 films watched.")
        #expect(Copy.for(.host, stage: .predicted).sample == "12 down, 38 to go. A head start the Academy can't match.")
        #expect(Copy.for(.host, stage: .shortlisted).sample == "12 down, 38 to go. The Academy's still deciding. You're not.")
        #expect(Copy.for(.host, stage: .nominated).sample == "12 down, 38 to go. The Academy watched all of these. Allegedly.")
        #expect(Copy.host.sample == Copy.for(.host, stage: .nominated).sample)
    }
}
