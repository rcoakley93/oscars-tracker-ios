import XCTest
@testable import OscarsTracker

/// Tests for OnboardingViewModel validation and computed properties.
/// Note: Tests focus on pure functions that don't require Supabase connection.
final class OnboardingViewModelTests: XCTestCase {

    var viewModel: OnboardingViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = OnboardingViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Username Length Validation Tests

    @MainActor
    func testIsLengthValid_validLength() {
        viewModel.username = "johndoe"
        XCTAssertTrue(viewModel.isLengthValid)
    }

    @MainActor
    func testIsLengthValid_minBoundary() {
        viewModel.username = "abc"
        XCTAssertTrue(viewModel.isLengthValid)
    }

    @MainActor
    func testIsLengthValid_maxBoundary() {
        viewModel.username = String(repeating: "a", count: 20)
        XCTAssertTrue(viewModel.isLengthValid)
    }

    @MainActor
    func testIsLengthValid_tooShort() {
        viewModel.username = "ab"
        XCTAssertFalse(viewModel.isLengthValid)
    }

    @MainActor
    func testIsLengthValid_tooLong() {
        viewModel.username = String(repeating: "a", count: 21)
        XCTAssertFalse(viewModel.isLengthValid)
    }

    @MainActor
    func testIsLengthValid_empty() {
        viewModel.username = ""
        XCTAssertFalse(viewModel.isLengthValid)
    }

    @MainActor
    func testIsLengthValid_singleChar() {
        viewModel.username = "a"
        XCTAssertFalse(viewModel.isLengthValid)
    }

    // MARK: - Username Format Validation Tests

    @MainActor
    func testIsFormatValid_alphanumeric() {
        viewModel.username = "john123"
        XCTAssertTrue(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_withUnderscore() {
        viewModel.username = "john_doe_123"
        XCTAssertTrue(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_allUppercase() {
        viewModel.username = "JOHNDOE"
        XCTAssertTrue(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_allLowercase() {
        viewModel.username = "johndoe"
        XCTAssertTrue(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_allNumbers() {
        viewModel.username = "123456"
        XCTAssertTrue(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_onlyUnderscores() {
        viewModel.username = "___"
        XCTAssertTrue(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_withSpaces() {
        viewModel.username = "john doe"
        XCTAssertFalse(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_withDash() {
        viewModel.username = "john-doe"
        XCTAssertFalse(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_withAtSymbol() {
        viewModel.username = "john@doe"
        XCTAssertFalse(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_withDot() {
        viewModel.username = "john.doe"
        XCTAssertFalse(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_withSpecialChars() {
        viewModel.username = "john!doe"
        XCTAssertFalse(viewModel.isFormatValid)
    }

    @MainActor
    func testIsFormatValid_empty() {
        viewModel.username = ""
        XCTAssertFalse(viewModel.isFormatValid)
    }

    // MARK: - Username Profanity Tests

    @MainActor
    func testContainsProfanity_noProfanity() {
        viewModel.username = "gooduser"
        XCTAssertFalse(viewModel.containsProfanity)
    }

    @MainActor
    func testContainsProfanity_exactMatch() {
        viewModel.username = "fuck"
        XCTAssertTrue(viewModel.containsProfanity)
    }

    @MainActor
    func testContainsProfanity_containsProfanity() {
        viewModel.username = "fuckuser"
        XCTAssertTrue(viewModel.containsProfanity)
    }

    @MainActor
    func testContainsProfanity_profanityInMiddle() {
        viewModel.username = "user_shit_name"
        XCTAssertTrue(viewModel.containsProfanity)
    }

    @MainActor
    func testContainsProfanity_profanityAtEnd() {
        viewModel.username = "usershit"
        XCTAssertTrue(viewModel.containsProfanity)
    }

    @MainActor
    func testContainsProfanity_caseInsensitive() {
        viewModel.username = "FUCK_user"
        XCTAssertTrue(viewModel.containsProfanity)
    }

    @MainActor
    func testContainsProfanity_mixedCase() {
        viewModel.username = "FuCkEr"
        XCTAssertTrue(viewModel.containsProfanity)
    }

    // MARK: - Combined Username Validation Tests

    @MainActor
    func testIsUsernameValid_allValid() {
        viewModel.username = "john_doe123"
        XCTAssertTrue(viewModel.isUsernameValid)
    }

    @MainActor
    func testIsUsernameValid_tooShort() {
        viewModel.username = "ab"
        XCTAssertFalse(viewModel.isUsernameValid)
    }

    @MainActor
    func testIsUsernameValid_tooLong() {
        viewModel.username = String(repeating: "a", count: 21)
        XCTAssertFalse(viewModel.isUsernameValid)
    }

    @MainActor
    func testIsUsernameValid_invalidFormat() {
        viewModel.username = "john@doe"
        XCTAssertFalse(viewModel.isUsernameValid)
    }

    @MainActor
    func testIsUsernameValid_hasProfanity() {
        viewModel.username = "fuckuser"
        XCTAssertFalse(viewModel.isUsernameValid)
    }

    @MainActor
    func testIsUsernameValid_empty() {
        viewModel.username = ""
        XCTAssertFalse(viewModel.isUsernameValid)
    }

    // MARK: - Validate Username Error Message Tests

    @MainActor
    func testValidateUsername_valid() {
        viewModel.username = "john_doe123"
        let error = viewModel.validateUsername()
        XCTAssertNil(error)
    }

    @MainActor
    func testValidateUsername_empty() {
        viewModel.username = ""
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Please enter a username.")
    }

    @MainActor
    func testValidateUsername_tooShort() {
        viewModel.username = "ab"
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Username must be 3-20 characters long.")
    }

    @MainActor
    func testValidateUsername_tooLong() {
        viewModel.username = String(repeating: "a", count: 21)
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Username must be 3-20 characters long.")
    }

    @MainActor
    func testValidateUsername_invalidFormat() {
        viewModel.username = "john@doe"
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Username can only contain letters, numbers, and underscores.")
    }

    @MainActor
    func testValidateUsername_containsProfanity() {
        viewModel.username = "fuckuser"
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Username contains inappropriate content.")
    }

    // MARK: - Validation Priority Tests

    @MainActor
    func testValidateUsername_emptyTakesPriority() {
        viewModel.username = ""
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Please enter a username.")
    }

    @MainActor
    func testValidateUsername_lengthTakesPriorityOverFormat() {
        viewModel.username = "a@" // 2 chars with invalid format
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Username must be 3-20 characters long.")
    }

    @MainActor
    func testValidateUsername_formatTakesPriorityOverProfanity() {
        viewModel.username = "fuck@user" // Invalid format and profanity
        let error = viewModel.validateUsername()
        XCTAssertEqual(error, "Username can only contain letters, numbers, and underscores.")
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
        let vm = OnboardingViewModel()
        XCTAssertEqual(vm.username, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Edge Cases

    @MainActor
    func testValidUsername_exactlyThreeChars() {
        viewModel.username = "abc"
        XCTAssertTrue(viewModel.isUsernameValid)
        XCTAssertNil(viewModel.validateUsername())
    }

    @MainActor
    func testValidUsername_exactlyTwentyChars() {
        viewModel.username = String(repeating: "a", count: 20)
        XCTAssertTrue(viewModel.isUsernameValid)
        XCTAssertNil(viewModel.validateUsername())
    }

    @MainActor
    func testValidUsername_mixedCaseAndNumbers() {
        viewModel.username = "JohnDoe_123_Test"
        XCTAssertTrue(viewModel.isUsernameValid)
    }

    @MainActor
    func testValidUsername_startsWithNumber() {
        viewModel.username = "123user"
        XCTAssertTrue(viewModel.isUsernameValid)
    }

    @MainActor
    func testValidUsername_startsWithUnderscore() {
        viewModel.username = "_username"
        XCTAssertTrue(viewModel.isUsernameValid)
    }

    @MainActor
    func testValidUsername_endsWithUnderscore() {
        viewModel.username = "username_"
        XCTAssertTrue(viewModel.isUsernameValid)
    }

    @MainActor
    func testValidUsername_doubleUnderscore() {
        viewModel.username = "user__name"
        XCTAssertTrue(viewModel.isUsernameValid)
    }
}
