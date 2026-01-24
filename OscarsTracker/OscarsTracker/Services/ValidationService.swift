import Foundation

/// Shared validation service for common validation logic across the app.
/// Extracts duplicated validation code from ViewModels for better testability and maintainability.
struct ValidationService {

    // MARK: - Profanity Filter

    /// Common profanity words to filter
    static let profanityList: Set<String> = [
        "fuck", "shit", "ass", "bitch", "damn", "crap", "bastard",
        "dick", "pussy", "cock", "cunt", "whore", "slut", "fag",
        "nigger", "nigga", "retard", "nazi", "hitler"
    ]

    /// Check if text contains profanity
    static func containsProfanity(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return profanityList.contains { profanity in
            lowercased.contains(profanity)
        }
    }

    // MARK: - Username Validation

    /// Username validation result
    enum UsernameValidationResult {
        case valid
        case empty
        case tooShort
        case tooLong
        case invalidFormat
        case containsProfanity

        var errorMessage: String? {
            switch self {
            case .valid:
                return nil
            case .empty:
                return "Please enter a username."
            case .tooShort, .tooLong:
                return "Username must be 3-20 characters long."
            case .invalidFormat:
                return "Username can only contain letters, numbers, and underscores."
            case .containsProfanity:
                return "Username contains inappropriate content."
            }
        }
    }

    /// Validate username with detailed result
    static func validateUsername(_ username: String) -> UsernameValidationResult {
        if username.isEmpty {
            return .empty
        }

        if username.count < 3 {
            return .tooShort
        }

        if username.count > 20 {
            return .tooLong
        }

        let usernameRegex = #"^[A-Za-z0-9_]+$"#
        if username.range(of: usernameRegex, options: .regularExpression) == nil {
            return .invalidFormat
        }

        if containsProfanity(username) {
            return .containsProfanity
        }

        return .valid
    }

    /// Check if username length is valid (3-20 characters)
    static func isUsernameLengthValid(_ username: String) -> Bool {
        username.count >= 3 && username.count <= 20
    }

    /// Check if username format is valid (alphanumeric and underscores only)
    static func isUsernameFormatValid(_ username: String) -> Bool {
        let usernameRegex = #"^[A-Za-z0-9_]+$"#
        return username.range(of: usernameRegex, options: .regularExpression) != nil
    }

    // MARK: - Group Name Validation

    /// Group name validation result
    enum GroupNameValidationResult {
        case valid
        case empty
        case tooShort
        case tooLong
        case containsProfanity

        var errorMessage: String? {
            switch self {
            case .valid:
                return nil
            case .empty:
                return "Please enter a group name."
            case .tooShort, .tooLong:
                return "Group name must be 3-30 characters long."
            case .containsProfanity:
                return "Group name contains inappropriate content."
            }
        }
    }

    /// Validate group name with detailed result
    static func validateGroupName(_ name: String) -> GroupNameValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            return .empty
        }

        if trimmed.count < 3 {
            return .tooShort
        }

        if trimmed.count > 30 {
            return .tooLong
        }

        if containsProfanity(trimmed) {
            return .containsProfanity
        }

        return .valid
    }

    /// Check if group name length is valid (3-30 characters)
    static func isGroupNameLengthValid(_ name: String) -> Bool {
        name.count >= 3 && name.count <= 30
    }

    // MARK: - Email Validation

    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    // MARK: - Password Validation

    /// Password validation result
    enum PasswordValidationResult {
        case valid
        case tooShort
        case missingUppercase
        case missingLowercase
        case missingNumber

        var errorMessage: String? {
            switch self {
            case .valid:
                return nil
            case .tooShort:
                return "Password must be at least 8 characters long."
            case .missingUppercase:
                return "Password must contain at least one uppercase letter."
            case .missingLowercase:
                return "Password must contain at least one lowercase letter."
            case .missingNumber:
                return "Password must contain at least one number."
            }
        }
    }

    /// Validate password with detailed result
    static func validatePassword(_ password: String) -> PasswordValidationResult {
        if password.count < 8 {
            return .tooShort
        }

        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            return .missingUppercase
        }

        if password.range(of: "[a-z]", options: .regularExpression) == nil {
            return .missingLowercase
        }

        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            return .missingNumber
        }

        return .valid
    }

    /// Password strength levels
    enum PasswordStrengthLevel {
        case none
        case weak
        case medium
        case strong
    }

    /// Calculate password strength
    static func passwordStrength(_ password: String) -> PasswordStrengthLevel {
        if password.isEmpty {
            return .none
        }

        var score = 0

        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { score += 1 }

        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        default:
            return .strong
        }
    }

    // MARK: - Invite Code Validation

    /// Check if invite code is valid format (6 characters, alphanumeric uppercase)
    static func isInviteCodeValid(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespaces).uppercased()
        let codeRegex = #"^[A-Z0-9]{6}$"#
        return trimmed.range(of: codeRegex, options: .regularExpression) != nil
    }

    /// Generate a random 6-character invite code
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}
