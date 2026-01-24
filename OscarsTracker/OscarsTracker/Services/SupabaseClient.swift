import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://mukucjdrafjndtlxvbsj.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11a3VjamRyYWZqbmR0bHh2YnNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTQzMDcsImV4cCI6MjA4MTE3MDMwN30.eH4itWcYDWM1qGdYrIpZ8Xrpq4Dumm9WBkEb9FY_YKI"
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
