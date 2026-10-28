import Foundation
import Testing
@testable import OscarsTracker

/// The stage switch and carry-over (P10-02), the app's half of the backend's
/// `stage-switch.test.mjs`: the Sample source goes predicted → shortlisted →
/// nominated by changing only `list_stage`, `nominations_announced` and the
/// data, and the app only refreshes. A watched film stays watched at every
/// stage and counts while it's on the list.
@MainActor
@Suite("Stage switch")
struct StageSwitchTests {
    private let user = SampleDataSource.userID

    private var nominees: Set<Int> { Set(SampleData.categories.flatMap { $0.nominations.compactMap(\.movie?.id) }) }

    /// The shortlist as loaded on Dec 15: Sound and International Feature
    /// shortlisted, and Sound's shortlist leaves 11 off. The same week's
    /// predicted refresh drops 12 from Adapted Screenplay, its only category.
    private var shortlist: [Contender] {
        SampleData.contenders(.shortlisted).filter {
            !($0.categoryId == 19 && $0.movieId == 11) && !($0.categoryId == 9 && $0.movieId == 12)
        }
    }

    private func predictedSeason() async -> (AppModel, SampleDataSource) {
        let data = SampleDataSource()
        data.config.listStage = .predicted
        data.contenderList = SampleData.contenders(.predicted)
        data.movieList += SampleData.contenderOnlyMovies
        data.announceNominations(false)
        let model = AppModel(data: data)
        await model.start()
        return (model, data)
    }

    @Test func aWatchedFilmCarriesOverAndCountsWhileItsOnTheList() async {
        let (model, data) = await predictedSeason()
        await model.films.toggleWatched(11, userID: user)
        await model.films.toggleWatched(12, userID: user)
        // 1, 4 and 7 from the sample, then the two contender-only films.
        #expect(model.films.watchedCount == 5)

        // Dec 15: the shortlists load and the flag flips.
        data.contenderList = shortlist
        data.config.listStage = .shortlisted
        await model.refresh()
        #expect(model.films.listStage == .shortlisted)
        // 11 is off Sound's shortlist but still a Best Picture contender.
        #expect(model.films.movieIDs(in: 19) == [2, 4, 5])
        #expect(model.films.list.contains { $0.id == 11 })
        // 12 dropped off every list: still watched, no longer counted.
        #expect(!model.films.list.contains { $0.id == 12 })
        #expect(model.films.isWatched(11) && model.films.isWatched(12))
        #expect(model.films.watchedCount == 4)
        #expect(model.films.watched.map(\.id).sorted() == [1, 4, 7, 11])

        // Jan 21: the nominations are announced and the flag flips.
        data.announceNominations(true)
        data.config.listStage = .nominated
        await model.refresh()
        #expect(model.films.listStage == .nominated)
        #expect(Set(model.films.list.map(\.id)) == nominees)
        #expect(model.films.isWatched(11) && model.films.isWatched(12))
        #expect(model.films.watchedCount == 3)
        #expect(model.films.toWatch.count == nominees.count - 3)
        // The server still has every watched record.
        #expect(data.watched == [1, 4, 7, 11, 12])
    }

    @Test func eachCategoryShowsItsOwnStage() async {
        let (model, data) = await predictedSeason()
        #expect(model.films.contenders.allSatisfy { $0.stage == .predicted })

        data.contenderList = shortlist
        data.config.listStage = .shortlisted
        await model.refresh()
        let stages = Dictionary(grouping: model.films.contenders, by: \.categoryId).mapValues { Set($0.map(\.stage)) }
        #expect(stages[10] == [.shortlisted])
        #expect(stages[19] == [.shortlisted])
        // Categories without an Academy shortlist keep their predicted contenders.
        #expect(stages[1] == [.predicted])
        #expect(stages[2] == [.predicted])
        #expect(model.films.listCategories.map(\.id) == [1, 2, 3, 9, 10, 19])
    }

    @Test func aWatchedFilmThatReturnsCountsAgain() async {
        let (model, data) = await predictedSeason()
        await model.films.toggleWatched(12, userID: user)
        data.contenderList = shortlist
        data.config.listStage = .shortlisted
        await model.refresh()
        #expect(model.films.watchedCount == 3)

        // A later refresh puts 12 back on Adapted Screenplay.
        data.contenderList = SampleData.contenders(.shortlisted)
        await model.refresh()
        #expect(model.films.watchedCount == 4)
        #expect(model.films.isWatched(12))
    }
}
