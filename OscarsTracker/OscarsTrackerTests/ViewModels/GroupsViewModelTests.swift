import XCTest
@testable import OscarsTracker

/// Tests for GroupsViewModel validation and computed properties.
/// Note: Tests focus on pure functions that don't require Supabase connection.
@MainActor
final class GroupsViewModelTests: XCTestCase {

    var viewModel: GroupsViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = GroupsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Group Name Length Validation Tests

    @MainActor
    func testIsNameLengthValid_validLength() {
        viewModel.newGroupName = "Movie Club"
        XCTAssertTrue(viewModel.isNameLengthValid)
    }

    @MainActor
    func testIsNameLengthValid_minBoundary() {
        viewModel.newGroupName = "ABC"
        XCTAssertTrue(viewModel.isNameLengthValid)
    }

    @MainActor
    func testIsNameLengthValid_maxBoundary() {
        viewModel.newGroupName = String(repeating: "a", count: 30)
        XCTAssertTrue(viewModel.isNameLengthValid)
    }

    @MainActor
    func testIsNameLengthValid_tooShort() {
        viewModel.newGroupName = "AB"
        XCTAssertFalse(viewModel.isNameLengthValid)
    }

    @MainActor
    func testIsNameLengthValid_tooLong() {
        viewModel.newGroupName = String(repeating: "a", count: 31)
        XCTAssertFalse(viewModel.isNameLengthValid)
    }

    @MainActor
    func testIsNameLengthValid_empty() {
        viewModel.newGroupName = ""
        XCTAssertFalse(viewModel.isNameLengthValid)
    }

    // MARK: - Group Name Profanity Tests

    @MainActor
    func testNameContainsProfanity_noProfanity() {
        viewModel.newGroupName = "Oscar Watchers"
        XCTAssertFalse(viewModel.nameContainsProfanity)
    }

    @MainActor
    func testNameContainsProfanity_containsProfanity() {
        viewModel.newGroupName = "The Shit Show"
        XCTAssertTrue(viewModel.nameContainsProfanity)
    }

    @MainActor
    func testNameContainsProfanity_profanityInMiddle() {
        viewModel.newGroupName = "Team Fuck Yeah"
        XCTAssertTrue(viewModel.nameContainsProfanity)
    }

    @MainActor
    func testNameContainsProfanity_caseInsensitive() {
        viewModel.newGroupName = "The SHIT Show"
        XCTAssertTrue(viewModel.nameContainsProfanity)
    }

    // MARK: - Combined Group Name Validation Tests

    @MainActor
    func testIsGroupNameValid_allValid() {
        viewModel.newGroupName = "Oscar Prediction Club"
        XCTAssertTrue(viewModel.isGroupNameValid)
    }

    @MainActor
    func testIsGroupNameValid_tooShort() {
        viewModel.newGroupName = "AB"
        XCTAssertFalse(viewModel.isGroupNameValid)
    }

    @MainActor
    func testIsGroupNameValid_tooLong() {
        viewModel.newGroupName = String(repeating: "a", count: 31)
        XCTAssertFalse(viewModel.isGroupNameValid)
    }

    @MainActor
    func testIsGroupNameValid_hasProfanity() {
        viewModel.newGroupName = "The Fuck Club"
        XCTAssertFalse(viewModel.isGroupNameValid)
    }

    // MARK: - Validate Group Name Tests

    @MainActor
    func testValidateGroupName_valid() {
        viewModel.newGroupName = "Movie Club"
        let error = viewModel.validateGroupName()
        XCTAssertNil(error)
    }

    @MainActor
    func testValidateGroupName_empty() {
        viewModel.newGroupName = ""
        let error = viewModel.validateGroupName()
        XCTAssertEqual(error, "Please enter a group name.")
    }

    @MainActor
    func testValidateGroupName_onlyWhitespace() {
        viewModel.newGroupName = "   "
        let error = viewModel.validateGroupName()
        XCTAssertEqual(error, "Please enter a group name.")
    }

    @MainActor
    func testValidateGroupName_tooShort() {
        viewModel.newGroupName = "AB"
        let error = viewModel.validateGroupName()
        XCTAssertEqual(error, "Group name must be 3-30 characters long.")
    }

    @MainActor
    func testValidateGroupName_tooLong() {
        viewModel.newGroupName = String(repeating: "a", count: 31)
        let error = viewModel.validateGroupName()
        XCTAssertEqual(error, "Group name must be 3-30 characters long.")
    }

    @MainActor
    func testValidateGroupName_containsProfanity() {
        viewModel.newGroupName = "The Shit Show"
        let error = viewModel.validateGroupName()
        XCTAssertEqual(error, "Group name contains inappropriate content.")
    }

    // MARK: - Invite Code Validation Tests

    @MainActor
    func testIsInviteCodeValid_validCode() {
        viewModel.inviteCodeInput = "ABC123"
        XCTAssertTrue(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_allLetters() {
        viewModel.inviteCodeInput = "ABCDEF"
        XCTAssertTrue(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_allNumbers() {
        viewModel.inviteCodeInput = "123456"
        XCTAssertTrue(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_lowercase() {
        viewModel.inviteCodeInput = "abc123"
        XCTAssertTrue(viewModel.isInviteCodeValid) // Should be case-insensitive
    }

    @MainActor
    func testIsInviteCodeValid_withWhitespace() {
        viewModel.inviteCodeInput = " ABC123 "
        XCTAssertTrue(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_empty() {
        viewModel.inviteCodeInput = ""
        XCTAssertFalse(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_tooShort() {
        viewModel.inviteCodeInput = "ABC12"
        XCTAssertFalse(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_tooLong() {
        viewModel.inviteCodeInput = "ABC1234"
        XCTAssertFalse(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_specialChars() {
        viewModel.inviteCodeInput = "ABC12!"
        XCTAssertFalse(viewModel.isInviteCodeValid)
    }

    @MainActor
    func testIsInviteCodeValid_withSpaces() {
        viewModel.inviteCodeInput = "ABC 12"
        XCTAssertFalse(viewModel.isInviteCodeValid)
    }

    // MARK: - Form Reset Tests

    @MainActor
    func testResetCreateForm() {
        viewModel.newGroupName = "Test Group"
        viewModel.errorMessage = "Some error"

        viewModel.resetCreateForm()

        XCTAssertEqual(viewModel.newGroupName, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testResetJoinForm() {
        viewModel.inviteCodeInput = "ABC123"
        viewModel.errorMessage = "Some error"

        viewModel.resetJoinForm()

        XCTAssertEqual(viewModel.inviteCodeInput, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Clear Error Tests

    @MainActor
    func testClearError() {
        viewModel.errorMessage = "Some error"
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Initial State Tests

    @MainActor
    func testInitialState() {
        let vm = GroupsViewModel()
        XCTAssertTrue(vm.myGroups.isEmpty)
        XCTAssertTrue(vm.joinedGroups.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.currentUserId)
        XCTAssertFalse(vm.showCreateSheet)
        XCTAssertFalse(vm.isCreating)
        XCTAssertFalse(vm.showJoinSheet)
        XCTAssertFalse(vm.isJoining)
        XCTAssertEqual(vm.newGroupName, "")
        XCTAssertEqual(vm.inviteCodeInput, "")
    }

    // MARK: - GroupWithMemberCount Tests

    func testGroupWithMemberCount_identifiable() {
        let group1 = GroupWithMemberCount(
            id: 1,
            name: "Group 1",
            inviteCode: "ABC123",
            createdBy: "user-1",
            memberCount: 5
        )

        let group2 = GroupWithMemberCount(
            id: 2,
            name: "Group 2",
            inviteCode: "DEF456",
            createdBy: "user-2",
            memberCount: 3
        )

        XCTAssertNotEqual(group1.id, group2.id)
    }

    func testGroupWithMemberCount_isOwner() {
        var group = GroupWithMemberCount(
            id: 1,
            name: "My Group",
            inviteCode: "ABC123",
            createdBy: "user-1",
            memberCount: 5,
            isOwner: true
        )

        XCTAssertTrue(group.isOwner)

        group.isOwner = false
        XCTAssertFalse(group.isOwner)
    }

    // MARK: - Edge Cases

    @MainActor
    func testGroupNameWithSpecialCharacters_valid() {
        viewModel.newGroupName = "Oscar's Winners 2024!"
        XCTAssertTrue(viewModel.isGroupNameValid)
    }

    @MainActor
    func testGroupNameWithEmoji_valid() {
        viewModel.newGroupName = "Movie Club 🎬"
        XCTAssertTrue(viewModel.isGroupNameValid)
    }

    @MainActor
    func testGroupNameWithLeadingTrailingSpaces() {
        viewModel.newGroupName = "  Movie Club  "
        // Validation should work, trimming happens during creation
        XCTAssertTrue(viewModel.isGroupNameValid) // Based on count of 14 chars including spaces
    }

    @MainActor
    func testInviteCodeMixedCase() {
        viewModel.inviteCodeInput = "AbC123"
        XCTAssertTrue(viewModel.isInviteCodeValid)
    }
}
