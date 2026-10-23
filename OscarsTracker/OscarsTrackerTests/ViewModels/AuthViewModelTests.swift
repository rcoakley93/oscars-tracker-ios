import XCTest
@testable import OscarsTracker

/// Tests for AuthViewModel validation and password strength logic.
/// Note: Tests focus on pure functions that don't require Supabase connection.
@MainActor
final class AuthViewModelTests: XCTestCase {

    var viewModel: AuthViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Email Validation Tests

    @MainActor
    func testIsValidEmail_validStandardEmail() {
        XCTAssertTrue(viewModel.isValidEmail("test@example.com"))
    }

    @MainActor
    func testIsValidEmail_validEmailWithSubdomain() {
        XCTAssertTrue(viewModel.isValidEmail("user@mail.example.com"))
    }

    @MainActor
    func testIsValidEmail_validEmailWithPlus() {
        XCTAssertTrue(viewModel.isValidEmail("user+tag@example.com"))
    }

    @MainActor
    func testIsValidEmail_validEmailWithNumbers() {
        XCTAssertTrue(viewModel.isValidEmail("user123@example456.com"))
    }

    @MainActor
    func testIsValidEmail_validEmailWithDots() {
        XCTAssertTrue(viewModel.isValidEmail("first.last@example.com"))
    }

    @MainActor
    func testIsValidEmail_validEmailWithUnderscore() {
        XCTAssertTrue(viewModel.isValidEmail("first_last@example.com"))
    }

    @MainActor
    func testIsValidEmail_invalidEmptyEmail() {
        XCTAssertFalse(viewModel.isValidEmail(""))
    }

    @MainActor
    func testIsValidEmail_invalidNoAtSymbol() {
        XCTAssertFalse(viewModel.isValidEmail("testexample.com"))
    }

    @MainActor
    func testIsValidEmail_invalidNoDomain() {
        XCTAssertFalse(viewModel.isValidEmail("test@"))
    }

    @MainActor
    func testIsValidEmail_invalidNoTLD() {
        XCTAssertFalse(viewModel.isValidEmail("test@example"))
    }

    @MainActor
    func testIsValidEmail_invalidShortTLD() {
        XCTAssertFalse(viewModel.isValidEmail("test@example.c"))
    }

    @MainActor
    func testIsValidEmail_invalidWithSpaces() {
        XCTAssertFalse(viewModel.isValidEmail("test @example.com"))
        XCTAssertFalse(viewModel.isValidEmail("test@ example.com"))
        XCTAssertFalse(viewModel.isValidEmail(" test@example.com"))
    }

    @MainActor
    func testIsValidEmail_invalidMultipleAtSymbols() {
        XCTAssertFalse(viewModel.isValidEmail("test@@example.com"))
        XCTAssertFalse(viewModel.isValidEmail("test@example@com"))
    }

    @MainActor
    func testIsValidEmail_invalidSpecialCharacters() {
        XCTAssertFalse(viewModel.isValidEmail("test!@example.com"))
    }

    // MARK: - Password Validation Tests

    @MainActor
    func testValidatePassword_validPassword() {
        let result = viewModel.validatePassword("Password1")
        XCTAssertNil(result, "Valid password should return nil")
    }

    @MainActor
    func testValidatePassword_validPasswordWithSpecialChars() {
        let result = viewModel.validatePassword("Password1!")
        XCTAssertNil(result)
    }

    @MainActor
    func testValidatePassword_validLongPassword() {
        let result = viewModel.validatePassword("MyVerySecurePassword123")
        XCTAssertNil(result)
    }

    @MainActor
    func testValidatePassword_invalidTooShort() {
        let result = viewModel.validatePassword("Pass1")
        XCTAssertEqual(result, "Password must be at least 8 characters long.")
    }

    @MainActor
    func testValidatePassword_invalidExactly7Chars() {
        let result = viewModel.validatePassword("Pass12A")
        XCTAssertEqual(result, "Password must be at least 8 characters long.")
    }

    @MainActor
    func testValidatePassword_validExactly8Chars() {
        let result = viewModel.validatePassword("Pass123A")
        XCTAssertNil(result)
    }

    @MainActor
    func testValidatePassword_invalidNoUppercase() {
        let result = viewModel.validatePassword("password1")
        XCTAssertEqual(result, "Password must contain at least one uppercase letter.")
    }

    @MainActor
    func testValidatePassword_invalidNoLowercase() {
        let result = viewModel.validatePassword("PASSWORD1")
        XCTAssertEqual(result, "Password must contain at least one lowercase letter.")
    }

    @MainActor
    func testValidatePassword_invalidNoNumber() {
        let result = viewModel.validatePassword("Passwordd")
        XCTAssertEqual(result, "Password must contain at least one number.")
    }

    @MainActor
    func testValidatePassword_invalidEmpty() {
        let result = viewModel.validatePassword("")
        XCTAssertEqual(result, "Password must be at least 8 characters long.")
    }

    @MainActor
    func testValidatePassword_invalidOnlySpaces() {
        let result = viewModel.validatePassword("        ")
        XCTAssertEqual(result, "Password must contain at least one uppercase letter.")
    }

    // MARK: - Password Strength Tests

    @MainActor
    func testPasswordStrength_emptyReturnsNone() {
        let strength = viewModel.passwordStrength("")
        XCTAssertEqual(strength, .none)
    }

    @MainActor
    func testPasswordStrength_shortLowercaseReturnsWeak() {
        let strength = viewModel.passwordStrength("abc")
        XCTAssertEqual(strength, .weak)
    }

    @MainActor
    func testPasswordStrength_onlyLowercaseReturnsWeak() {
        let strength = viewModel.passwordStrength("password")
        XCTAssertEqual(strength, .weak)
    }

    @MainActor
    func testPasswordStrength_shortMixedCaseReturnsWeak() {
        let strength = viewModel.passwordStrength("Passwo")
        XCTAssertEqual(strength, .weak)
    }

    @MainActor
    func testPasswordStrength_mediumWithMixedCase() {
        let strength = viewModel.passwordStrength("Password")
        XCTAssertEqual(strength, .medium)
    }

    @MainActor
    func testPasswordStrength_mediumWithNumber() {
        let strength = viewModel.passwordStrength("Password1")
        XCTAssertEqual(strength, .medium)
    }

    @MainActor
    func testPasswordStrength_strongWithAllCriteria() {
        let strength = viewModel.passwordStrength("Password123!")
        XCTAssertEqual(strength, .strong)
    }

    @MainActor
    func testPasswordStrength_strongWithLongPassword() {
        let strength = viewModel.passwordStrength("MySecurePassword1!")
        XCTAssertEqual(strength, .strong)
    }

    @MainActor
    func testPasswordStrength_mediumBoundary() {
        // score = 4 (>=8: 1, uppercase: 1, lowercase: 1, number: 1) = medium
        let strength = viewModel.passwordStrength("Passwor1")
        XCTAssertEqual(strength, .medium)
    }

    @MainActor
    func testPasswordStrength_strongBoundary() {
        // score = 5 (>=8: 1, >=12: 1, uppercase: 1, lowercase: 1, number: 1) = strong
        let strength = viewModel.passwordStrength("Password1234")
        XCTAssertEqual(strength, .strong)
    }

    // MARK: - PasswordStrength Enum Tests

    func testPasswordStrengthColor() {
        XCTAssertEqual(PasswordStrength.none.color, "textMuted")
        XCTAssertEqual(PasswordStrength.weak.color, "destructive")
        XCTAssertEqual(PasswordStrength.medium.color, "goldPrimary")
        XCTAssertEqual(PasswordStrength.strong.color, "green")
    }

    func testPasswordStrengthLabel() {
        XCTAssertEqual(PasswordStrength.none.label, "")
        XCTAssertEqual(PasswordStrength.weak.label, "Weak")
        XCTAssertEqual(PasswordStrength.medium.label, "Medium")
        XCTAssertEqual(PasswordStrength.strong.label, "Strong")
    }

    // MARK: - Initial State Tests

    @MainActor
    func testInitialState() {
        let vm = AuthViewModel()
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.currentUser)
        XCTAssertFalse(vm.needsOnboarding)
    }

    // MARK: - Clear Error Tests

    @MainActor
    func testClearError() {
        viewModel.errorMessage = "Some error"
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Complete Onboarding Tests

    @MainActor
    func testCompleteOnboarding() {
        viewModel.needsOnboarding = true
        XCTAssertTrue(viewModel.needsOnboarding)

        viewModel.completeOnboarding()
        XCTAssertFalse(viewModel.needsOnboarding)
    }

    // MARK: - Edge Cases

    @MainActor
    func testValidatePassword_unicodeCharacters() {
        // Password with unicode should still work if it meets requirements
        let result = viewModel.validatePassword("Pässwörd1")
        XCTAssertNil(result)
    }

    @MainActor
    func testIsValidEmail_internationalDomain() {
        XCTAssertTrue(viewModel.isValidEmail("user@example.co.uk"))
        XCTAssertTrue(viewModel.isValidEmail("user@example.io"))
    }

    @MainActor
    func testPasswordStrength_onlySpecialChars() {
        let strength = viewModel.passwordStrength("!@#$%^&*")
        XCTAssertEqual(strength, .weak) // Only gets +1 for special chars
    }

    @MainActor
    func testPasswordStrength_veryLongPassword() {
        let strength = viewModel.passwordStrength("ThisIsAVeryLongPasswordWithUpperAndLower123!")
        XCTAssertEqual(strength, .strong)
    }
}
