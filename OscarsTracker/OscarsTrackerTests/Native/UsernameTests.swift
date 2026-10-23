import Testing
@testable import OscarsTracker

@Suite("Usernames")
struct UsernameTests {
    @Test(arguments: ["Glass", "ClassicFan", "Hitchcock_fan", "Dickens", "Passenger", "Scrappy", "Bassist"])
    func realWordsAreAllowed(name: String) {
        #expect(ValidationService.validateUsername(name) == .valid)
    }

    @Test(arguments: ["ass", "big_ass", "BigAss", "dick99", "nazi_fan", "whatthefuck", "user_shit_name"])
    func profanityIsBlocked(name: String) {
        #expect(ValidationService.validateUsername(name) == .containsProfanity)
    }

    @Test func splitsOnSeparatorsAndCamelCase() {
        #expect(ValidationService.words(in: "Big_Glass2Fan") == ["big", "glass", "fan"])
        #expect(ValidationService.words(in: "bigGlassFan") == ["big", "glass", "fan"])
    }

    @Test func everySuggestionPassesTheValidator() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            let name = ValidationService.suggestedUsername(using: &generator)
            #expect(ValidationService.validateUsername(name) == .valid, "\(name)")
        }
    }
}
