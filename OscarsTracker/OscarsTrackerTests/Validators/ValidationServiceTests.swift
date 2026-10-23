import XCTest
@testable import OscarsTracker

@MainActor
final class ValidationServiceTests: XCTestCase {

    // MARK: - Email Validation Tests

    func testValidEmail_standardFormat() {
        XCTAssertTrue(ValidationService.isValidEmail("test@example.com"))
    }

    func testValidEmail_withSubdomain() {
        XCTAssertTrue(ValidationService.isValidEmail("user@mail.example.com"))
    }

    func testValidEmail_withPlus() {
        XCTAssertTrue(ValidationService.isValidEmail("user+tag@example.com"))
    }

    func testValidEmail_withNumbers() {
        XCTAssertTrue(ValidationService.isValidEmail("user123@example456.com"))
    }

    func testValidEmail_withDots() {
        XCTAssertTrue(ValidationService.isValidEmail("first.last@example.com"))
    }

    func testInvalidEmail_empty() {
        XCTAssertFalse(ValidationService.isValidEmail(""))
    }

    func testInvalidEmail_noAtSymbol() {
        XCTAssertFalse(ValidationService.isValidEmail("testexample.com"))
    }

    func testInvalidEmail_noDomain() {
        XCTAssertFalse(ValidationService.isValidEmail("test@"))
    }

    func testInvalidEmail_noTLD() {
        XCTAssertFalse(ValidationService.isValidEmail("test@example"))
    }

    func testInvalidEmail_shortTLD() {
        XCTAssertFalse(ValidationService.isValidEmail("test@example.c"))
    }

    func testInvalidEmail_spacesInEmail() {
        XCTAssertFalse(ValidationService.isValidEmail("test @example.com"))
    }

    func testInvalidEmail_multipleAtSymbols() {
        XCTAssertFalse(ValidationService.isValidEmail("test@@example.com"))
    }

    // MARK: - Password Validation Tests

    func testValidPassword_meetsAllRequirements() {
        let result = ValidationService.validatePassword("Password1")
        XCTAssertEqual(result, .valid)
    }

    func testValidPassword_withSpecialCharacters() {
        let result = ValidationService.validatePassword("Password1!")
        XCTAssertEqual(result, .valid)
    }

    func testValidPassword_longPassword() {
        let result = ValidationService.validatePassword("MyVeryLongPassword123")
        XCTAssertEqual(result, .valid)
    }

    func testInvalidPassword_tooShort() {
        let result = ValidationService.validatePassword("Pass1")
        XCTAssertEqual(result, .tooShort)
        XCTAssertEqual(result.errorMessage, "Password must be at least 8 characters long.")
    }

    func testInvalidPassword_noUppercase() {
        let result = ValidationService.validatePassword("password1")
        XCTAssertEqual(result, .missingUppercase)
        XCTAssertEqual(result.errorMessage, "Password must contain at least one uppercase letter.")
    }

    func testInvalidPassword_noLowercase() {
        let result = ValidationService.validatePassword("PASSWORD1")
        XCTAssertEqual(result, .missingLowercase)
        XCTAssertEqual(result.errorMessage, "Password must contain at least one lowercase letter.")
    }

    func testInvalidPassword_noNumber() {
        let result = ValidationService.validatePassword("Passwordd")
        XCTAssertEqual(result, .missingNumber)
        XCTAssertEqual(result.errorMessage, "Password must contain at least one number.")
    }

    func testInvalidPassword_empty() {
        let result = ValidationService.validatePassword("")
        XCTAssertEqual(result, .tooShort)
    }

    // MARK: - Password Strength Tests

    func testPasswordStrength_empty() {
        XCTAssertEqual(ValidationService.passwordStrength(""), .none)
    }

    func testPasswordStrength_weak_shortLowercase() {
        XCTAssertEqual(ValidationService.passwordStrength("abc"), .weak)
    }

    func testPasswordStrength_weak_onlyLowercase() {
        XCTAssertEqual(ValidationService.passwordStrength("password"), .weak)
    }

    func testPasswordStrength_medium_mixedCase() {
        XCTAssertEqual(ValidationService.passwordStrength("Password"), .medium)
    }

    func testPasswordStrength_medium_withNumber() {
        XCTAssertEqual(ValidationService.passwordStrength("Password1"), .medium)
    }

    func testPasswordStrength_strong_allCriteria() {
        XCTAssertEqual(ValidationService.passwordStrength("Password123!"), .strong)
    }

    func testPasswordStrength_strong_longWithSpecial() {
        XCTAssertEqual(ValidationService.passwordStrength("MySecurePassword1!"), .strong)
    }

    // MARK: - Username Validation Tests

    func testValidUsername_standard() {
        let result = ValidationService.validateUsername("john_doe")
        XCTAssertEqual(result, .valid)
    }

    func testValidUsername_minLength() {
        let result = ValidationService.validateUsername("abc")
        XCTAssertEqual(result, .valid)
    }

    func testValidUsername_maxLength() {
        let result = ValidationService.validateUsername("abcdefghijklmnopqrst") // 20 chars
        XCTAssertEqual(result, .valid)
    }

    func testValidUsername_withNumbers() {
        let result = ValidationService.validateUsername("user123")
        XCTAssertEqual(result, .valid)
    }

    func testValidUsername_allNumbers() {
        let result = ValidationService.validateUsername("12345")
        XCTAssertEqual(result, .valid)
    }

    func testValidUsername_withUnderscores() {
        let result = ValidationService.validateUsername("john_doe_123")
        XCTAssertEqual(result, .valid)
    }

    func testInvalidUsername_empty() {
        let result = ValidationService.validateUsername("")
        XCTAssertEqual(result, .empty)
        XCTAssertEqual(result.errorMessage, "Please enter a username.")
    }

    func testInvalidUsername_tooShort() {
        let result = ValidationService.validateUsername("ab")
        XCTAssertEqual(result, .tooShort)
        XCTAssertEqual(result.errorMessage, "Username must be 3-20 characters long.")
    }

    func testInvalidUsername_tooLong() {
        let result = ValidationService.validateUsername("abcdefghijklmnopqrstu") // 21 chars
        XCTAssertEqual(result, .tooLong)
        XCTAssertEqual(result.errorMessage, "Username must be 3-20 characters long.")
    }

    func testInvalidUsername_withSpaces() {
        let result = ValidationService.validateUsername("john doe")
        XCTAssertEqual(result, .invalidFormat)
        XCTAssertEqual(result.errorMessage, "Username can only contain letters, numbers, and underscores.")
    }

    func testInvalidUsername_withSpecialChars() {
        let result = ValidationService.validateUsername("john@doe")
        XCTAssertEqual(result, .invalidFormat)
    }

    func testInvalidUsername_withDash() {
        let result = ValidationService.validateUsername("john-doe")
        XCTAssertEqual(result, .invalidFormat)
    }

    func testInvalidUsername_containsProfanity() {
        let result = ValidationService.validateUsername("fuckuser")
        XCTAssertEqual(result, .containsProfanity)
        XCTAssertEqual(result.errorMessage, "Username contains inappropriate content.")
    }

    func testInvalidUsername_profanityInMiddle() {
        let result = ValidationService.validateUsername("user_shit_name")
        XCTAssertEqual(result, .containsProfanity)
    }

    func testInvalidUsername_profanityCaseInsensitive() {
        let result = ValidationService.validateUsername("FUCK_user")
        XCTAssertEqual(result, .containsProfanity)
    }

    // MARK: - Username Helper Methods Tests

    func testIsUsernameLengthValid_valid() {
        XCTAssertTrue(ValidationService.isUsernameLengthValid("johndoe"))
    }

    func testIsUsernameLengthValid_minBoundary() {
        XCTAssertTrue(ValidationService.isUsernameLengthValid("abc"))
    }

    func testIsUsernameLengthValid_maxBoundary() {
        XCTAssertTrue(ValidationService.isUsernameLengthValid(String(repeating: "a", count: 20)))
    }

    func testIsUsernameLengthValid_tooShort() {
        XCTAssertFalse(ValidationService.isUsernameLengthValid("ab"))
    }

    func testIsUsernameLengthValid_tooLong() {
        XCTAssertFalse(ValidationService.isUsernameLengthValid(String(repeating: "a", count: 21)))
    }

    func testIsUsernameFormatValid_alphanumeric() {
        XCTAssertTrue(ValidationService.isUsernameFormatValid("john123"))
    }

    func testIsUsernameFormatValid_withUnderscore() {
        XCTAssertTrue(ValidationService.isUsernameFormatValid("john_doe"))
    }

    func testIsUsernameFormatValid_invalidChars() {
        XCTAssertFalse(ValidationService.isUsernameFormatValid("john@doe"))
    }

    // MARK: - Group Name Validation Tests

    func testValidGroupName_standard() {
        let result = ValidationService.validateGroupName("Movie Buffs")
        XCTAssertEqual(result, .valid)
    }

    func testValidGroupName_minLength() {
        let result = ValidationService.validateGroupName("ABC")
        XCTAssertEqual(result, .valid)
    }

    func testValidGroupName_maxLength() {
        let result = ValidationService.validateGroupName(String(repeating: "a", count: 30))
        XCTAssertEqual(result, .valid)
    }

    func testValidGroupName_withSpecialChars() {
        let result = ValidationService.validateGroupName("Oscar Winners 2024!")
        XCTAssertEqual(result, .valid)
    }

    func testInvalidGroupName_empty() {
        let result = ValidationService.validateGroupName("")
        XCTAssertEqual(result, .empty)
        XCTAssertEqual(result.errorMessage, "Please enter a group name.")
    }

    func testInvalidGroupName_onlyWhitespace() {
        let result = ValidationService.validateGroupName("   ")
        XCTAssertEqual(result, .empty)
    }

    func testInvalidGroupName_tooShort() {
        let result = ValidationService.validateGroupName("AB")
        XCTAssertEqual(result, .tooShort)
        XCTAssertEqual(result.errorMessage, "Group name must be 3-30 characters long.")
    }

    func testInvalidGroupName_tooLong() {
        let result = ValidationService.validateGroupName(String(repeating: "a", count: 31))
        XCTAssertEqual(result, .tooLong)
        XCTAssertEqual(result.errorMessage, "Group name must be 3-30 characters long.")
    }

    func testInvalidGroupName_containsProfanity() {
        let result = ValidationService.validateGroupName("The Shit Show")
        XCTAssertEqual(result, .containsProfanity)
        XCTAssertEqual(result.errorMessage, "Group name contains inappropriate content.")
    }

    func testGroupName_trimsWhitespace() {
        let result = ValidationService.validateGroupName("  Movie Club  ")
        XCTAssertEqual(result, .valid)
    }

    // MARK: - Group Name Helper Methods Tests

    func testIsGroupNameLengthValid_valid() {
        XCTAssertTrue(ValidationService.isGroupNameLengthValid("Movie Club"))
    }

    func testIsGroupNameLengthValid_minBoundary() {
        XCTAssertTrue(ValidationService.isGroupNameLengthValid("abc"))
    }

    func testIsGroupNameLengthValid_maxBoundary() {
        XCTAssertTrue(ValidationService.isGroupNameLengthValid(String(repeating: "a", count: 30)))
    }

    func testIsGroupNameLengthValid_tooShort() {
        XCTAssertFalse(ValidationService.isGroupNameLengthValid("ab"))
    }

    func testIsGroupNameLengthValid_tooLong() {
        XCTAssertFalse(ValidationService.isGroupNameLengthValid(String(repeating: "a", count: 31)))
    }

    // MARK: - Profanity Filter Tests

    func testContainsProfanity_noProfanity() {
        XCTAssertFalse(ValidationService.containsProfanity("Hello World"))
    }

    func testContainsProfanity_exactMatch() {
        XCTAssertTrue(ValidationService.containsProfanity("fuck"))
    }

    func testContainsProfanity_withinWord() {
        XCTAssertTrue(ValidationService.containsProfanity("whatthefuck"))
    }

    func testContainsProfanity_caseInsensitive() {
        XCTAssertTrue(ValidationService.containsProfanity("FUCK"))
        XCTAssertTrue(ValidationService.containsProfanity("FuCk"))
    }

    func testContainsProfanity_multipleWords() {
        XCTAssertTrue(ValidationService.containsProfanity("this is shit"))
    }

    func testContainsProfanity_allProfanityListItems() {
        for word in ValidationService.profanityList {
            XCTAssertTrue(ValidationService.containsProfanity(word), "Should detect: \(word)")
        }
    }

    // MARK: - Invite Code Validation Tests

    func testValidInviteCode_standard() {
        XCTAssertTrue(ValidationService.isInviteCodeValid("ABC123"))
    }

    func testValidInviteCode_allLetters() {
        XCTAssertTrue(ValidationService.isInviteCodeValid("ABCDEF"))
    }

    func testValidInviteCode_allNumbers() {
        XCTAssertTrue(ValidationService.isInviteCodeValid("123456"))
    }

    func testValidInviteCode_lowercase() {
        XCTAssertTrue(ValidationService.isInviteCodeValid("abc123"))
    }

    func testValidInviteCode_withWhitespace() {
        XCTAssertTrue(ValidationService.isInviteCodeValid(" ABC123 "))
    }

    func testInvalidInviteCode_empty() {
        XCTAssertFalse(ValidationService.isInviteCodeValid(""))
    }

    func testInvalidInviteCode_tooShort() {
        XCTAssertFalse(ValidationService.isInviteCodeValid("ABC12"))
    }

    func testInvalidInviteCode_tooLong() {
        XCTAssertFalse(ValidationService.isInviteCodeValid("ABC1234"))
    }

    func testInvalidInviteCode_specialChars() {
        XCTAssertFalse(ValidationService.isInviteCodeValid("ABC12!"))
    }

    // MARK: - Invite Code Generation Tests

    func testGenerateInviteCode_correctLength() {
        let code = ValidationService.generateInviteCode()
        XCTAssertEqual(code.count, 6)
    }

    func testGenerateInviteCode_validFormat() {
        let code = ValidationService.generateInviteCode()
        XCTAssertTrue(ValidationService.isInviteCodeValid(code))
    }

    func testGenerateInviteCode_uppercase() {
        let code = ValidationService.generateInviteCode()
        XCTAssertEqual(code, code.uppercased())
    }

    func testGenerateInviteCode_uniqueness() {
        let codes = (0..<100).map { _ in ValidationService.generateInviteCode() }
        let uniqueCodes = Set(codes)
        // With 36^6 = 2+ billion combinations, 100 codes should all be unique
        XCTAssertEqual(uniqueCodes.count, 100)
    }
}
