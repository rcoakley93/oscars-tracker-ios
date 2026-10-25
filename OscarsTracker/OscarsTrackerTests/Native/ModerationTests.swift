import Foundation
import Testing
@testable import OscarsTracker

/// Report, block and the name filter (guideline 1.2, P6-16).
@MainActor
@Suite("Moderation", .serialized)
struct ModerationTests {
    @Test func aReportKeepsTheNameAndATrimmedNote() async {
        let data = SampleDataSource()
        data.reports = []
        let store = ModerationStore(data: data)
        #expect(await store.report(.person(id: "u-chris", name: "Chris"), reason: .offensiveName, details: "  rude  "))
        #expect(await store.report(.group(id: 2, name: "Family pool"), reason: .spam, details: "   "))
        #expect(store.reportsSent == 2)
        #expect(data.reports.map(\.reportedName) == ["Chris", "Family pool"])
        #expect(data.reports.map(\.details) == ["rude", nil])
        #expect(data.reports.map(\.kind) == [.user, .group])
    }

    @Test func aLongNoteIsCutToTheLimit() async {
        let data = SampleDataSource()
        data.reports = []
        let store = ModerationStore(data: data)
        _ = await store.report(.person(id: "u-sam", name: "Sam"), reason: .other, details: String(repeating: "x", count: 600))
        #expect(data.reports.first?.details?.count == ModerationStore.detailsLimit)
    }

    @Test func aFailedReportSaysWhyAndCountsNothing() async {
        let data = SampleDataSource()
        let store = ModerationStore(data: data)
        #expect(await store.report(.group(id: 99, name: "Not mine"), reason: .spam, details: "") == false)
        #expect(store.reportError != nil)
        #expect(store.actionError == nil)
        #expect(store.reportsSent == 0)
    }

    @Test func blockingHidesThemFromTheBoards() async {
        let data = SampleDataSource()
        let model = AppModel(data: data)
        await model.refresh()
        #expect(model.leaderboard.entries(nil).contains { $0.userId == "u-jordan" })
        model.navigation.selectedPersonID = "u-jordan"

        #expect(await model.block("u-jordan", name: "Jordan"))
        #expect(model.moderation.isBlocked("u-jordan"))
        #expect(!model.leaderboard.entries(nil).contains { $0.userId == "u-jordan" })
        #expect(!model.leaderboard.entries(1).contains { $0.userId == "u-jordan" })
        #expect(model.navigation.selectedPersonID == nil)
        // The ranks close up behind them.
        #expect(model.leaderboard.entries(nil).map(\.rank) == Array(1...model.leaderboard.entries(nil).count))

        await model.unblock("u-jordan")
        #expect(!model.moderation.isBlocked("u-jordan"))
        #expect(model.leaderboard.entries(nil).contains { $0.userId == "u-jordan" })
    }

    @Test func aBlockTheServerRefusesIsTakenBack() async {
        let data = SampleDataSource()
        let store = ModerationStore(data: data)
        await store.load()
        data.failure = .offline
        #expect(await store.block("u-sam", name: "Sam") == false)
        #expect(!store.isBlocked("u-sam"))
        #expect(store.actionError == .offline)
    }

    @Test func anUnblockTheServerRefusesIsTakenBack() async {
        let data = SampleDataSource()
        data.blocked = [BlockedUser(userId: "u-sam", username: "Sam", avatarUrl: nil, blockedAt: nil)]
        let store = ModerationStore(data: data)
        await store.load()
        data.failure = .offline
        #expect(await store.unblock("u-sam") == false)
        #expect(store.isBlocked("u-sam"))
    }

    @Test func blockedPeopleLoadAndResetAtSignOut() async {
        let data = SampleDataSource()
        data.blocked = [BlockedUser(userId: "u-sam", username: "Sam", avatarUrl: nil, blockedAt: nil)]
        let model = AppModel(data: data)
        await model.refresh()
        #expect(model.moderation.blocked.map(\.name) == ["Sam"])
        await model.signOut()
        #expect(model.moderation.blocked.isEmpty)
    }

    // MARK: - The admin's queue

    @Test func clearingANameClosesEveryOpenReportOnThem() async {
        let data = SampleDataSource()
        data.isAdmin = true
        let admin = AdminStore(data: data)
        await admin.loadReports()
        #expect(admin.openReports.count == 3)
        let chris = try! #require(admin.openReports.first { $0.reportedUserId == "u-chris" })
        await admin.resolve(chris, .clearName)
        #expect(admin.openReports.map(\.id) == [3])
        #expect(data.reports.filter { $0.reportedUserId == "u-chris" }.allSatisfy { $0.status == .actioned })
    }

    @Test func dismissingClosesTheReport() async {
        let data = SampleDataSource()
        data.isAdmin = true
        let admin = AdminStore(data: data)
        await admin.loadReports()
        await admin.resolve(admin.openReports.last!, .dismiss)
        #expect(admin.reports.first { $0.id == 3 }?.status == .dismissed)
        #expect(admin.openReports.count == 2)
    }

    @Test func aRefusedResolutionPutsTheReportsBack() async {
        let data = SampleDataSource()
        data.isAdmin = true
        let admin = AdminStore(data: data)
        await admin.loadReports()
        data.isAdmin = false
        await admin.resolve(admin.openReports[0], .dismiss)
        #expect(admin.openReports.count == 3)
        #expect(admin.actionError == .adminsOnly)
    }

    @Test func reportsDecodeFromTheQueue() throws {
        let json = Data("""
        [{"id": 4, "kind": "group", "reason": "offensive_name", "details": null, "reported_name": "Bad name",
          "current_name": null, "reported_user_id": null, "group_id": null, "reporter_name": "sam",
          "status": "open", "created_at": null}]
        """.utf8)
        let report = try #require(try JSONDecoder().decode([ContentReport].self, from: json).first)
        #expect(report.reason == .offensiveName)
        #expect(report.targetIsGone)
        let blocked = try JSONDecoder().decode([BlockedUser].self, from: Data(#"[{"user_id": "u1", "username": null, "avatar_url": null, "blocked_at": null}]"#.utf8))
        #expect(blocked.first?.name == "Someone")
    }

    // MARK: - Errors and names

    @Test func moderationErrorsAreMatchedByCode() {
        #expect(AppError(serverMessage: "That name isn't allowed", code: "NAM01", hint: "name_not_allowed") == .nameNotAllowed)
        #expect(AppError(serverMessage: "x", hint: "name_invalid") == .nameInvalid)
        #expect(AppError(serverMessage: "You can't join this group", code: "GRP03") == .blockedFromGroup)
        #expect(AppError(serverMessage: "x", code: "RPT01") == .tooManyReports)
        for error in [AppError.nameNotAllowed, .nameInvalid, .blockedFromGroup, .tooManyReports] {
            #expect(!error.message.isEmpty)
            #expect(!error.message.contains("!"))
        }
    }

    /// The same cases as the server's filter in `npm run test:db`.
    @Test(arguments: ["whatthefuck", "Sh1tHead", "big_ass_fan", "bigAssFan", "B1gAss", "@ss_fan", "Sh!tlist"])
    func theFilterSeesThroughSwaps(name: String) {
        #expect(ValidationService.containsProfanity(name))
    }

    @Test(arguments: ["Bigass", "BigGlassFan", "HitchcockFan", "Classic_Cinema", "Dickens4Life", "Scumble"])
    func theFilterLetsRealWordsThrough(name: String) {
        #expect(!ValidationService.containsProfanity(name))
    }

    @Test func usernamesAndGroupNamesSayTheSameThing() {
        #expect(ProfileStore.usernameProblem("Sh1tHead") == "That name isn't allowed. Try another.")
        #expect(GroupsStore.nameProblem("Fuck Club") == "That name isn't allowed. Try another.")
    }

    @Test func reportsOpenTheirSheet() {
        let navigation = AppNavigation()
        navigation.sheet = .report(.group(id: 2, name: "Family pool"))
        #expect(navigation.sheet?.id == "report-group-2")
    }
}
