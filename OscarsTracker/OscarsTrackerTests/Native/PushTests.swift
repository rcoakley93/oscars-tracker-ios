import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Push")
struct PushTests {
    @Test func savesTheTokenAsHexAndForgetsItAtSignOut() async {
        let data = SampleDataSource()
        let model = AppModel(data: data)
        await model.session.restore()
        await model.push.didRegister(deviceToken: Data([0x0a, 0xff, 0x10]), userID: model.session.userID)
        #expect(data.devices == ["0aff10": .sandbox])
        await model.signOut()
        #expect(data.devices.isEmpty)
    }

    @Test func aTokenFromBeforeSignInIsSavedAfter() async {
        let data = SampleDataSource()
        let store = PushStore(data: data)
        await store.didRegister(deviceToken: Data([1, 2]), userID: nil)
        #expect(data.devices.isEmpty)
        await store.signedIn()
        #expect(data.devices["0102"] == .sandbox)
    }

    @Test func savesCountOnlySuccessfulWrites() async {
        let data = SampleDataSource()
        let films = FilmsStore(data: data)
        await films.load(userID: SampleDataSource.userID)
        data.failure = .offline
        await films.toggleWatched(2, userID: SampleDataSource.userID)
        #expect(films.saves == 0)
        data.failure = nil
        await films.toggleWatched(2, userID: SampleDataSource.userID)
        #expect(films.saves == 1)
    }

    @Test(arguments: [
        ("/ballot", AppNavigation.Tab.ballot), ("/board", .board), ("/plan", .plan), ("/search", .films), ("/nonsense", .films),
    ])
    func opensTabs(path: String, tab: AppNavigation.Tab) {
        let navigation = AppNavigation()
        navigation.open(path: path)
        #expect(navigation.tab == tab)
    }

    @Test func opensAFilmACategoryAndAGroup() {
        let navigation = AppNavigation()
        navigation.open(path: "/movie/12")
        #expect(navigation.sheet == .movie(12))
        navigation.open(path: "/category/3")
        #expect(navigation.tab == .ballot)
        #expect(navigation.selectedCategoryID == 3)
        navigation.open(path: "/group/4")
        #expect(navigation.tab == .groups)
        #expect(navigation.selectedGroupID == 4)
    }
}
