import Foundation
import Testing
@testable import OscarsTracker

/// Push reminders' switches, voice and time zone (P6-04).
@MainActor
@Suite("Reminders", .serialized)
struct ReminderTests {
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    init() {
        UserDefaults.standard.removeObject(forKey: Voice.storageKey)
    }

    @Test func firstLoadSavesTheDevicesVoiceAndTimeZone() async {
        let data = SampleDataSource()
        UserDefaults.standard.set(Voice.classic.rawValue, forKey: Voice.storageKey)
        defer { UserDefaults.standard.removeObject(forKey: Voice.storageKey) }
        let store = PushStore(data: data)
        await store.loadPreferences(userID: SampleDataSource.userID, timeZone: tokyo)
        #expect(data.preferences == NotificationPreferences(voice: "classic", timeZone: "Asia/Tokyo"))
        #expect(store.preferences == data.preferences)
        #expect(store.preferences.watchPlan == false)
    }

    @Test func savedSwitchesLoadAndNothingIsResavedWhenTheyMatch() async {
        let data = SampleDataSource()
        let saved = NotificationPreferences(nominations: false, watchPlan: true, timeZone: "Asia/Tokyo")
        data.preferences = saved
        let store = PushStore(data: data)
        await store.loadPreferences(userID: SampleDataSource.userID, timeZone: tokyo)
        #expect(store.preferences == saved)
        data.preferences = nil
        await store.loadPreferences(userID: SampleDataSource.userID, timeZone: tokyo)
        #expect(data.preferences?.nominations == true, "no row: the defaults are saved")
    }

    @Test func aSwitchSaves() async {
        let data = SampleDataSource()
        let store = PushStore(data: data)
        await store.set(.watchPlan, true)
        await store.set(.results, false)
        #expect(data.preferences?.watchPlan == true)
        #expect(data.preferences?.results == false)
        #expect(store.preferences[.watchPlan])
    }

    @Test func aFailedSaveRollsBackAndSaysSo() async {
        let data = SampleDataSource()
        let store = PushStore(data: data)
        data.failure = .offline
        await store.set(.ballotLock, false)
        #expect(store.preferences.ballotLock)
        #expect(store.actionError == .offline)
        #expect(data.preferences == nil)
    }

    @Test func offlineLoadKeepsWhatsShown() async {
        let data = SampleDataSource()
        let store = PushStore(data: data)
        await store.set(.watchPlan, true)
        data.failure = .offline
        await store.loadPreferences(userID: SampleDataSource.userID, timeZone: tokyo)
        #expect(store.preferences.watchPlan)
    }

    @Test func changingTheVoiceSendsIt() async {
        let data = SampleDataSource()
        let store = PushStore(data: data)
        await store.setVoice(.classic)
        #expect(data.preferences?.voice == "classic")
        data.preferences = nil
        await store.setVoice(.classic)
        #expect(data.preferences == nil, "unchanged: nothing saved")
    }

    @Test func signingOutForgetsThem() async {
        let data = SampleDataSource()
        let store = PushStore(data: data)
        await store.set(.nominations, false)
        await store.signingOut()
        #expect(store.preferences == .defaults)
    }

    @Test func signInLoadsThem() async {
        let data = SampleDataSource()
        data.preferences = NotificationPreferences(results: false, timeZone: TimeZone.current.identifier)
        let model = AppModel(data: data)
        await model.start()
        #expect(model.push.preferences.results == false)
    }

    @Test func everyReminderHasASwitchThatReadsAndWrites() {
        var preferences = NotificationPreferences.defaults
        for reminder in NotificationPreferences.Reminder.allCases {
            #expect(!reminder.title.isEmpty && !reminder.detail.isEmpty)
            preferences[reminder].toggle()
        }
        #expect(preferences == NotificationPreferences(nominations: false, watchPlan: true, ballotLock: false, results: false))
    }

    @Test func decodesTheServersRow() throws {
        let json = #"{"user_id":"x","nominations":true,"watch_plan":true,"ballot_lock":false,"results":true,"voice":"classic","time_zone":"Europe/London","updated_at":"2026-10-24T00:00:00Z"}"#
        let decoded = try JSONDecoder().decode(NotificationPreferences.self, from: Data(json.utf8))
        #expect(decoded == NotificationPreferences(watchPlan: true, ballotLock: false, voice: "classic", timeZone: "Europe/London"))
    }

    @Test func theAdminSendsTheNominationsPushOnce() async {
        let data = SampleDataSource()
        data.isAdmin = true
        data.devices = ["01": .sandbox, "02": .production]
        let admin = AdminStore(data: data)
        await admin.load()
        #expect(await admin.sendNominationsPush() == 2)
        #expect(await admin.sendNominationsPush() == 0)
        data.isAdmin = false
        #expect(await admin.sendNominationsPush() == nil)
        #expect(admin.actionError == .adminsOnly)
    }
}
