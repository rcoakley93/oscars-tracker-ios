import Foundation
import Testing
@testable import OscarsTracker

@Suite("Invite links")
struct InviteLinkTests {
    @Test func readsTheCodeFromBothKindsOfLink() {
        #expect(InviteLink.code(in: URL(string: "oscarstracker://join/oscar9")!, host: nil) == "OSCAR9")
        #expect(InviteLink.code(in: URL(string: "https://example.app/join/OSCAR9")!, host: "example.app") == "OSCAR9")
    }

    @Test func ignoresOtherLinks() {
        #expect(InviteLink.code(in: URL(string: "oscarstracker://auth/callback")!, host: nil) == nil)
        #expect(InviteLink.code(in: URL(string: "https://other.app/join/OSCAR9")!, host: "example.app") == nil)
        #expect(InviteLink.code(in: URL(string: "https://example.app/join/abc")!, host: "example.app") == nil)
        #expect(InviteLink.code(in: URL(string: "https://example.app/join/OSCAR9")!, host: nil) == nil)
    }

    @Test func buildsTheLinkOnlyWithASite() {
        #expect(InviteLink.url(code: "OSCAR9", host: "example.app")?.absoluteString == "https://example.app/join/OSCAR9")
        #expect(InviteLink.url(code: "OSCAR9", host: nil) == nil)
    }

    /// The app's own host, from SITE_HOST: the one its applinks entitlement claims.
    @Test func opensTheSitesInviteLinks() {
        #expect(InviteLink.siteHost == "oscarstracker.com")
        #expect(InviteLink.code(in: URL(string: "https://oscarstracker.com/join/OSCAR9")!) == "OSCAR9")
        #expect(InviteLink.url(code: "OSCAR9")?.absoluteString == "https://oscarstracker.com/join/OSCAR9")
    }

    @Test func normalizesTypedCodes() {
        #expect(InviteLink.normalized(" os-car 9x ") == "OSCAR9")
        #expect(InviteLink.isValid("OSCAR9"))
        #expect(!InviteLink.isValid("OSCAR"))
    }
}

@MainActor
@Suite("Groups", .serialized)
struct GroupsTests {
    private let user = SampleDataSource.userID

    @Test func joiningCelebratesOnlyOnSuccess() async {
        let store = GroupsStore(data: SampleDataSource())
        await store.load(userID: user)
        #expect(await store.join(code: "WRONG1", userID: user) == nil)
        #expect(store.actionError == .invalidInviteCode)
        #expect(store.joins == 0)
        let joined = await store.join(code: "friend", userID: user)
        #expect(joined?.groupName == "Film club")
        #expect(store.joins == 1)
        #expect(store.groups.contains { $0.id == joined?.groupId })
    }

    @Test func groupNamesAreChecked() {
        #expect(GroupsStore.nameProblem("") != nil)
        #expect(GroupsStore.nameProblem("ab") != nil)
        #expect(GroupsStore.nameProblem(String(repeating: "a", count: 31)) != nil)
        #expect(GroupsStore.nameProblem("Movies LLC") == nil)
    }

    @Test func anInviteLinkIsKeptUntilYoureIn() async {
        defer { UserDefaults.standard.removeObject(forKey: "invite.pending") }
        let session = SessionStore(data: SampleDataSource(signedIn: false))
        #expect(await session.open(URL(string: "oscarstracker://join/OSCAR9")!) == false)
        #expect(session.pendingInviteCode == "OSCAR9")
        #expect(SessionStore(data: SampleDataSource()).pendingInviteCode == "OSCAR9")
    }

    @Test func bothVoicesHaveTheGroupLines() {
        for voice in Voice.allCases {
            let copy = Copy.for(voice)
            #expect(!copy.groupsJoined("Movies LLC").isEmpty)
            #expect(!copy.groupsEmpty.title.isEmpty)
        }
    }
}
