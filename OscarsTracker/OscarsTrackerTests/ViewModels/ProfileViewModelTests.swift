import XCTest
@testable import OscarsTracker

/// Tests for ProfileViewModel validation and computed properties.
/// Note: Tests focus on pure functions that don't require Supabase connection.
final class ProfileViewModelTests: XCTestCase {

    var viewModel: ProfileViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = ProfileViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Username Length Validation Tests

    @MainActor
    func testIsUsernameLengthValid_validLength() {
        viewModel.editedUsername = "johndoe"
        XCTAssertTrue(viewModel.isUsernameLengthValid)
    }

    @MainActor
    func testIsUsernameLengthValid_minBoundary() {
        viewModel.editedUsername = "abc"
        XCTAssertTrue(viewModel.isUsernameLengthValid)
    }

    @MainActor
    func testIsUsernameLengthValid_maxBoundary() {
        viewModel.editedUsername = String(repeating: "a", count: 20)
        XCTAssertTrue(viewModel.isUsernameLengthValid)
    }

    @MainActor
    func testIsUsernameLengthValid_tooShort() {
        viewModel.editedUsername = "ab"
        XCTAssertFalse(viewModel.isUsernameLengthValid)
    }

    @MainActor
    func testIsUsernameLengthValid_tooLong() {
        viewModel.editedUsername = String(repeating: "a", count: 21)
        XCTAssertFalse(viewModel.isUsernameLengthValid)
    }

    @MainActor
    func testIsUsernameLengthValid_empty() {
        viewModel.editedUsername = ""
        XCTAssertFalse(viewModel.isUsernameLengthValid)
    }

    // MARK: - Username Format Validation Tests

    @MainActor
    func testIsUsernameFormatValid_alphanumeric() {
        viewModel.editedUsername = "john123"
        XCTAssertTrue(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_withUnderscore() {
        viewModel.editedUsername = "john_doe_123"
        XCTAssertTrue(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_allUppercase() {
        viewModel.editedUsername = "JOHNDOE"
        XCTAssertTrue(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_allNumbers() {
        viewModel.editedUsername = "123456"
        XCTAssertTrue(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_withSpaces() {
        viewModel.editedUsername = "john doe"
        XCTAssertFalse(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_withDash() {
        viewModel.editedUsername = "john-doe"
        XCTAssertFalse(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_withAtSymbol() {
        viewModel.editedUsername = "john@doe"
        XCTAssertFalse(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_withSpecialChars() {
        viewModel.editedUsername = "john!doe"
        XCTAssertFalse(viewModel.isUsernameFormatValid)
    }

    @MainActor
    func testIsUsernameFormatValid_empty() {
        viewModel.editedUsername = ""
        XCTAssertFalse(viewModel.isUsernameFormatValid)
    }

    // MARK: - Username Profanity Tests

    @MainActor
    func testUsernameContainsProfanity_noProfanity() {
        viewModel.editedUsername = "gooduser"
        XCTAssertFalse(viewModel.usernameContainsProfanity)
    }

    @MainActor
    func testUsernameContainsProfanity_containsProfanity() {
        viewModel.editedUsername = "fuckuser"
        XCTAssertTrue(viewModel.usernameContainsProfanity)
    }

    @MainActor
    func testUsernameContainsProfanity_profanityInMiddle() {
        viewModel.editedUsername = "user_shit_name"
        XCTAssertTrue(viewModel.usernameContainsProfanity)
    }

    @MainActor
    func testUsernameContainsProfanity_caseInsensitive() {
        viewModel.editedUsername = "FUCK_user"
        XCTAssertTrue(viewModel.usernameContainsProfanity)
    }

    // MARK: - Combined Username Validation Tests

    @MainActor
    func testIsEditedUsernameValid_allValid() {
        viewModel.editedUsername = "john_doe123"
        XCTAssertTrue(viewModel.isEditedUsernameValid)
    }

    @MainActor
    func testIsEditedUsernameValid_tooShort() {
        viewModel.editedUsername = "ab"
        XCTAssertFalse(viewModel.isEditedUsernameValid)
    }

    @MainActor
    func testIsEditedUsernameValid_invalidFormat() {
        viewModel.editedUsername = "john@doe"
        XCTAssertFalse(viewModel.isEditedUsernameValid)
    }

    @MainActor
    func testIsEditedUsernameValid_hasProfanity() {
        viewModel.editedUsername = "fuckuser"
        XCTAssertFalse(viewModel.isEditedUsernameValid)
    }

    // MARK: - Password Validation Tests

    @MainActor
    func testIsNewPasswordLengthValid_valid() {
        viewModel.newPassword = "password"
        XCTAssertTrue(viewModel.isNewPasswordLengthValid)
    }

    @MainActor
    func testIsNewPasswordLengthValid_tooShort() {
        viewModel.newPassword = "pass"
        XCTAssertFalse(viewModel.isNewPasswordLengthValid)
    }

    @MainActor
    func testIsNewPasswordLengthValid_exactlyEight() {
        viewModel.newPassword = "12345678"
        XCTAssertTrue(viewModel.isNewPasswordLengthValid)
    }

    @MainActor
    func testNewPasswordHasUppercase_valid() {
        viewModel.newPassword = "Password"
        XCTAssertTrue(viewModel.newPasswordHasUppercase)
    }

    @MainActor
    func testNewPasswordHasUppercase_invalid() {
        viewModel.newPassword = "password"
        XCTAssertFalse(viewModel.newPasswordHasUppercase)
    }

    @MainActor
    func testNewPasswordHasLowercase_valid() {
        viewModel.newPassword = "Password"
        XCTAssertTrue(viewModel.newPasswordHasLowercase)
    }

    @MainActor
    func testNewPasswordHasLowercase_invalid() {
        viewModel.newPassword = "PASSWORD"
        XCTAssertFalse(viewModel.newPasswordHasLowercase)
    }

    @MainActor
    func testNewPasswordHasNumber_valid() {
        viewModel.newPassword = "Password1"
        XCTAssertTrue(viewModel.newPasswordHasNumber)
    }

    @MainActor
    func testNewPasswordHasNumber_invalid() {
        viewModel.newPassword = "Password"
        XCTAssertFalse(viewModel.newPasswordHasNumber)
    }

    @MainActor
    func testPasswordsMatch_matching() {
        viewModel.newPassword = "Password1"
        viewModel.confirmNewPassword = "Password1"
        XCTAssertTrue(viewModel.passwordsMatch)
    }

    @MainActor
    func testPasswordsMatch_notMatching() {
        viewModel.newPassword = "Password1"
        viewModel.confirmNewPassword = "Password2"
        XCTAssertFalse(viewModel.passwordsMatch)
    }

    @MainActor
    func testPasswordsMatch_emptyPassword() {
        viewModel.newPassword = ""
        viewModel.confirmNewPassword = ""
        XCTAssertFalse(viewModel.passwordsMatch)
    }

    @MainActor
    func testIsNewPasswordValid_allCriteriaMet() {
        viewModel.newPassword = "Password1"
        XCTAssertTrue(viewModel.isNewPasswordValid)
    }

    @MainActor
    func testIsNewPasswordValid_missingUppercase() {
        viewModel.newPassword = "password1"
        XCTAssertFalse(viewModel.isNewPasswordValid)
    }

    @MainActor
    func testIsNewPasswordValid_missingLowercase() {
        viewModel.newPassword = "PASSWORD1"
        XCTAssertFalse(viewModel.isNewPasswordValid)
    }

    @MainActor
    func testIsNewPasswordValid_missingNumber() {
        viewModel.newPassword = "Password"
        XCTAssertFalse(viewModel.isNewPasswordValid)
    }

    @MainActor
    func testIsNewPasswordValid_tooShort() {
        viewModel.newPassword = "Pass1"
        XCTAssertFalse(viewModel.isNewPasswordValid)
    }

    // MARK: - Change Password Form Validation Tests

    @MainActor
    func testIsChangePasswordFormValid_allValid() {
        viewModel.currentPassword = "oldpassword"
        viewModel.newPassword = "Password1"
        viewModel.confirmNewPassword = "Password1"
        XCTAssertTrue(viewModel.isChangePasswordFormValid)
    }

    @MainActor
    func testIsChangePasswordFormValid_emptyCurrentPassword() {
        viewModel.currentPassword = ""
        viewModel.newPassword = "Password1"
        viewModel.confirmNewPassword = "Password1"
        XCTAssertFalse(viewModel.isChangePasswordFormValid)
    }

    @MainActor
    func testIsChangePasswordFormValid_invalidNewPassword() {
        viewModel.currentPassword = "oldpassword"
        viewModel.newPassword = "weak"
        viewModel.confirmNewPassword = "weak"
        XCTAssertFalse(viewModel.isChangePasswordFormValid)
    }

    @MainActor
    func testIsChangePasswordFormValid_passwordsDontMatch() {
        viewModel.currentPassword = "oldpassword"
        viewModel.newPassword = "Password1"
        viewModel.confirmNewPassword = "Password2"
        XCTAssertFalse(viewModel.isChangePasswordFormValid)
    }

    // MARK: - Password Strength Tests

    @MainActor
    func testNewPasswordStrength_empty() {
        viewModel.newPassword = ""
        XCTAssertEqual(viewModel.newPasswordStrength, .none)
    }

    @MainActor
    func testNewPasswordStrength_weak() {
        viewModel.newPassword = "abc"
        XCTAssertEqual(viewModel.newPasswordStrength, .weak)
    }

    @MainActor
    func testNewPasswordStrength_medium() {
        viewModel.newPassword = "Password"
        XCTAssertEqual(viewModel.newPasswordStrength, .medium)
    }

    @MainActor
    func testNewPasswordStrength_strong() {
        viewModel.newPassword = "Password123!"
        XCTAssertEqual(viewModel.newPasswordStrength, .strong)
    }

    // MARK: - Member Since Formatting Tests

    @MainActor
    func testMemberSinceFormatted_validDate() {
        viewModel.profile = Profile(
            id: "123",
            username: "test",
            avatarUrl: nil,
            createdAt: "2024-01-15T10:30:00.000Z"
        )

        let formatted = viewModel.memberSinceFormatted()

        XCTAssertNotEqual(formatted, "Unknown")
        // Exact format depends on locale, but should not be "Unknown"
    }

    @MainActor
    func testMemberSinceFormatted_noFractionalSeconds() {
        viewModel.profile = Profile(
            id: "123",
            username: "test",
            avatarUrl: nil,
            createdAt: "2024-01-15T10:30:00Z"
        )

        let formatted = viewModel.memberSinceFormatted()

        XCTAssertNotEqual(formatted, "Unknown")
    }

    @MainActor
    func testMemberSinceFormatted_invalidDate() {
        viewModel.profile = Profile(
            id: "123",
            username: "test",
            avatarUrl: nil,
            createdAt: "invalid-date"
        )

        let formatted = viewModel.memberSinceFormatted()

        XCTAssertEqual(formatted, "Unknown")
    }

    @MainActor
    func testMemberSinceFormatted_nilCreatedAt() {
        viewModel.profile = Profile(
            id: "123",
            username: "test",
            avatarUrl: nil,
            createdAt: nil
        )

        let formatted = viewModel.memberSinceFormatted()

        XCTAssertEqual(formatted, "Unknown")
    }

    @MainActor
    func testMemberSinceFormatted_nilProfile() {
        viewModel.profile = nil

        let formatted = viewModel.memberSinceFormatted()

        XCTAssertEqual(formatted, "Unknown")
    }

    // MARK: - Edit Username State Tests

    @MainActor
    func testStartEditingUsername() {
        viewModel.profile = Profile(id: "123", username: "existinguser", avatarUrl: nil, createdAt: nil)

        viewModel.startEditingUsername()

        XCTAssertTrue(viewModel.isEditingUsername)
        XCTAssertEqual(viewModel.editedUsername, "existinguser")
        XCTAssertNil(viewModel.usernameSuccessMessage)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testStartEditingUsername_nilUsername() {
        viewModel.profile = Profile(id: "123", username: nil, avatarUrl: nil, createdAt: nil)

        viewModel.startEditingUsername()

        XCTAssertTrue(viewModel.isEditingUsername)
        XCTAssertEqual(viewModel.editedUsername, "")
    }

    @MainActor
    func testCancelEditingUsername() {
        viewModel.isEditingUsername = true
        viewModel.editedUsername = "newname"
        viewModel.errorMessage = "Some error"

        viewModel.cancelEditingUsername()

        XCTAssertFalse(viewModel.isEditingUsername)
        XCTAssertEqual(viewModel.editedUsername, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Change Password State Tests

    @MainActor
    func testOpenChangePasswordSheet() {
        viewModel.currentPassword = "old"
        viewModel.newPassword = "new"
        viewModel.confirmNewPassword = "new"
        viewModel.errorMessage = "error"

        viewModel.openChangePasswordSheet()

        XCTAssertTrue(viewModel.showChangePasswordSheet)
        XCTAssertEqual(viewModel.currentPassword, "")
        XCTAssertEqual(viewModel.newPassword, "")
        XCTAssertEqual(viewModel.confirmNewPassword, "")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.changePasswordSuccessMessage)
    }

    @MainActor
    func testCancelChangePassword() {
        viewModel.showChangePasswordSheet = true
        viewModel.currentPassword = "current"
        viewModel.newPassword = "new"
        viewModel.confirmNewPassword = "new"
        viewModel.errorMessage = "error"

        viewModel.cancelChangePassword()

        XCTAssertFalse(viewModel.showChangePasswordSheet)
        XCTAssertEqual(viewModel.currentPassword, "")
        XCTAssertEqual(viewModel.newPassword, "")
        XCTAssertEqual(viewModel.confirmNewPassword, "")
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
        let vm = ProfileViewModel()
        XCTAssertNil(vm.profile)
        XCTAssertEqual(vm.watchedCount, 0)
        XCTAssertEqual(vm.predictionsMade, 0)
        XCTAssertEqual(vm.correctPredictions, 0)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isEditingUsername)
        XCTAssertEqual(vm.editedUsername, "")
        XCTAssertFalse(vm.isSavingUsername)
        XCTAssertNil(vm.usernameSuccessMessage)
        XCTAssertFalse(vm.showChangePasswordSheet)
        XCTAssertEqual(vm.currentPassword, "")
        XCTAssertEqual(vm.newPassword, "")
        XCTAssertEqual(vm.confirmNewPassword, "")
        XCTAssertFalse(vm.isChangingPassword)
        XCTAssertNil(vm.changePasswordSuccessMessage)
        XCTAssertFalse(vm.isDeletingAccount)
    }
}

// MARK: - Profile Model Extension for Tests

extension Profile {
    init(id: String, username: String?, avatarUrl: String?, createdAt: String?) {
        self.init(
            id: id,
            username: username,
            avatarUrl: avatarUrl,
            createdAt: createdAt
        )
    }
}
