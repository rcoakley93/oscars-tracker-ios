import Foundation

/// Group invites (screens.md, 3.7): `https://<site>/join/<code>`, a universal
/// link (P5-03), and the older `oscarstracker://join/<code>`, still accepted.
/// Codes are six characters from `LiveDataSource.newInviteCode()`'s alphabet.
nonisolated enum InviteLink {
    /// The website's host from Info.plist (`SITE_HOST`), or nil until it's chosen.
    static var siteHost: String? {
        (Bundle.main.object(forInfoDictionaryKey: "SiteHost") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    /// The link to share, or nil while there's no website: then the code goes alone.
    static func url(code: String, host: String? = siteHost) -> URL? {
        host.flatMap { URL(string: "https://\($0)/join/\(code)") }
    }

    /// The code in an invite link, uppercased; nil for any other link.
    static func code(in url: URL, host: String? = siteHost) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        let code: String?
        switch url.scheme {
        case "oscarstracker" where url.host() == "join":
            code = parts.first
        case "https" where host != nil && url.host() == host && parts.first == "join":
            code = parts.dropFirst().first
        default:
            code = nil
        }
        return code.map(normalized).flatMap { isValid($0) ? $0 : nil }
    }

    /// What a typed or pasted code becomes: no spaces, uppercase, at most six.
    static func normalized(_ text: String) -> String {
        String(text.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
    }

    static func isValid(_ code: String) -> Bool {
        code.count == 6 && code.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }
}
