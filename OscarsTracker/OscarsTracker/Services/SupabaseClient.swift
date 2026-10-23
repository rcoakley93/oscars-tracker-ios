import Foundation
import Supabase

/// Public Supabase settings, from `Config/Shared.xcconfig` through Info.plist.
enum SupabaseConfig {
    static let projectURL: URL = {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "SupabaseHost") as? String,
              !host.isEmpty,
              let url = URL(string: "https://\(host)") else {
            fatalError("SupabaseHost is missing from Info.plist. Check Config/Shared.xcconfig.")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String, !key.isEmpty else {
            fatalError("SupabaseAnonKey is missing from Info.plist. Check Config/Shared.xcconfig.")
        }
        return key
    }()
}

final class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
