import Foundation
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Profile")
struct ProfileTests {
    private let user = SampleDataSource.userID

    @Test func anAppleAccountRevokesBeforeDeleting() async {
        let data = SampleDataSource()
        data.accountProvider = .apple
        let model = AppModel(data: data)
        await model.start()
        #expect(await model.deleteAccount(appleAuthorizationCode: "code-1"))
        #expect(data.revokedAppleCodes == ["code-1"])
        #expect(model.session.userID == nil)
    }

    @Test func anAppleAccountWithoutACodeIsNotDeleted() async {
        let data = SampleDataSource()
        data.accountProvider = .apple
        let model = AppModel(data: data)
        await model.start()
        #expect(await model.deleteAccount() == false)
        #expect(data.signedIn)
        #expect(model.session.userID == user)
        #expect(model.profile.actionError != nil)
    }

    @Test func passwordsFollowTheRules() async {
        let data = SampleDataSource()
        let store = ProfileStore(data: data)
        #expect(await store.changePassword("short") == false)
        #expect(store.actionError == .weakPassword)
        #expect(await store.changePassword("Longer1password"))
        #expect(data.newPassword == "Longer1password")
    }

    @Test func loadsTheAccountAndPastSeasons() async {
        let store = ProfileStore(data: SampleDataSource())
        await store.load(userID: user)
        await store.loadHistory(userID: user)
        #expect(store.account?.provider == .email)
        #expect(store.history.map(\.number) == [98])
    }

    @Test func decodesASeason() throws {
        let json = #"[{"ceremony_id":1,"number":98,"name":"98th Academy Awards","ceremony_at":"2026-03-15T23:00:00+00:00","watched_count":41,"correct_count":15,"points":20,"score":15,"scoring":"traditional","rank":3,"players":212}]"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let seasons = try decoder.decode([SeasonResult].self, from: Data(json.utf8))
        #expect(seasons.first?.players == 212)
    }
}
