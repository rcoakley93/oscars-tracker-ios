import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://your-project.supabase.co")!
    static let anonKey = "your-anon-key"
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
