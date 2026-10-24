import Foundation
import Supabase

/// `AppDataSource` backed by the Supabase project. Errors come back as
/// `AppError`, with the server's messages mapped to friendly text.
final class LiveDataSource: AppDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientManager.shared.client) {
        self.client = client
    }

    private func run<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw AppError(error)
        }
    }

    // MARK: - Session

    func currentUserID() async -> String? {
        try? await client.auth.session.user.id.uuidString.lowercased()
    }

    func signIn(email: String, password: String) async throws -> String {
        try await run {
            try await client.auth.signIn(email: email, password: password).user.id.uuidString.lowercased()
        }
    }

    /// Returns the new user's id, or nil when the project asks for email
    /// confirmation first (no session yet).
    func signUp(email: String, password: String) async throws -> String? {
        try await run {
            let response = try await client.auth.signUp(email: email, password: password)
            return response.session?.user.id.uuidString.lowercased()
        }
    }

    func signOut() async throws {
        try await run { try await client.auth.signOut() }
    }

    /// Where auth emails and the Google sheet send people back to. Each must
    /// be in the Supabase project's allowed redirect URLs.
    static let googleRedirect = URL(string: "oscarstracker://auth-callback")!
    static let resetRedirect = URL(string: "oscarstracker://reset-password")!

    func signInWithApple(idToken: String, nonce: String) async throws -> String {
        try await run {
            try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
                .user.id.uuidString.lowercased()
        }
    }

    /// Supabase's Google OAuth in an `ASWebAuthenticationSession`, using the
    /// Google provider the project already has, so accounts match the web's.
    func signInWithGoogle() async throws -> String {
        try await run {
            try await client.auth.signInWithOAuth(provider: .google, redirectTo: Self.googleRedirect)
                .user.id.uuidString.lowercased()
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await run {
            try await client.auth.resetPasswordForEmail(email, redirectTo: Self.resetRedirect)
        }
    }

    func openAuthLink(_ url: URL) async throws -> String {
        try await run {
            try await client.auth.session(from: url).user.id.uuidString.lowercased()
        }
    }

    func updatePassword(_ password: String) async throws {
        try await run {
            _ = try await client.auth.update(user: UserAttributes(password: password))
        }
    }

    // MARK: - Season

    func activeCeremony() async throws -> Ceremony? {
        try await run {
            let rows: [Ceremony] = try await client.from("ceremonies")
                .select("id, number, name, ceremony_at, ballot_lock_at, is_active")
                .eq("is_active", value: true)
                .limit(1)
                .execute()
                .value
            return rows.first
        }
    }

    private nonisolated struct BucketsRow: Decodable {
        let value: [String: [Int]]
    }

    func runtimeBuckets() async throws -> [RuntimeBucket] {
        try await run {
            let rows: [BucketsRow] = try await client.from("app_config")
                .select("value")
                .eq("key", value: "runtime_buckets")
                .execute()
                .value
            return rows.first.map { RuntimeBucket.parse($0.value) } ?? []
        }
    }

    // MARK: - Films and watched

    func movies() async throws -> [Movie] {
        try await run {
            try await client.from("movies").select().order("title").execute().value
        }
    }

    func watchedMovieIDs(userID: String) async throws -> Set<Int> {
        try await run {
            let rows: [UserWatched] = try await client.from("user_watched")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            return Set(rows.map(\.movieId))
        }
    }

    func offers(movieID: Int) async throws -> [WatchOffer] {
        try await run {
            try await client.from("movie_provider_availability")
                .select("id, availability_type, providers(name, logo_path)")
                .eq("movie_id", value: movieID)
                .eq("region", value: "US")
                .execute()
                .value
        }
    }

    func seenInGroups(movieID: Int) async throws -> [GroupSeen] {
        try await run {
            try await client.rpc("get_movie_seen_in_groups", params: ["p_movie_id": movieID]).execute().value
        }
    }

    private nonisolated struct WatchedInsert: Encodable {
        let user_id: String
        let movie_id: Int
    }

    func setWatched(_ watched: Bool, movieID: Int, userID: String) async throws {
        try await run {
            if watched {
                try await client.from("user_watched")
                    .upsert(WatchedInsert(user_id: userID, movie_id: movieID), onConflict: "user_id,movie_id", ignoreDuplicates: true)
                    .execute()
            } else {
                try await client.from("user_watched")
                    .delete()
                    .eq("user_id", value: userID)
                    .eq("movie_id", value: movieID)
                    .execute()
            }
        }
    }

    // MARK: - Ballot

    private nonisolated struct NominationRow: Decodable {
        let id: Int
        let category_id: Int?
        let detail_text: String?
        let is_winner: Bool?
        let movie: Movie?
    }

    func ballot() async throws -> [BallotCategory] {
        try await run {
            let categories: [Category] = try await client.from("categories")
                .select()
                .order("points_value", ascending: false)
                .order("name")
                .execute()
                .value
            let nominations: [NominationRow] = try await client.from("nominations")
                .select("id, category_id, detail_text, is_winner, movie:movies(*)")
                .execute()
                .value
            let byCategory = Dictionary(grouping: nominations, by: { $0.category_id ?? -1 })
            return categories.map { category in
                BallotCategory(
                    id: category.id,
                    name: category.name,
                    pointsValue: category.pointsValue ?? 1,
                    nominations: (byCategory[category.id] ?? [])
                        .map { BallotNominee(id: $0.id, movie: $0.movie, personName: $0.detail_text, isWinner: $0.is_winner ?? false) }
                        .sorted { ($0.personName ?? $0.movie?.title ?? "") < ($1.personName ?? $1.movie?.title ?? "") }
                )
            }
        }
    }

    func picks(userID: String) async throws -> [Int: Int] {
        try await run {
            let rows: [UserPrediction] = try await client.from("user_predictions")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            return Dictionary(rows.map { ($0.categoryId, $0.nominationId) }, uniquingKeysWith: { _, latest in latest })
        }
    }

    private nonisolated struct PickUpsert: Encodable {
        let user_id: String
        let category_id: Int
        let nomination_id: Int
    }

    func savePick(categoryID: Int, nominationID: Int, userID: String) async throws {
        try await run {
            try await client.from("user_predictions")
                .upsert(PickUpsert(user_id: userID, category_id: categoryID, nomination_id: nominationID), onConflict: "user_id,category_id")
                .execute()
        }
    }

    // MARK: - Watch plan

    func plan(userID: String) async throws -> [WatchPlanItem] {
        try await run {
            try await client.from("watch_plan")
                .select("id, user_id, movie_id, planned_date, created_at, movie:movies(*)")
                .eq("user_id", value: userID)
                .order("planned_date")
                .execute()
                .value
        }
    }

    private nonisolated struct PlanInsert: Encodable {
        let user_id: String
        let movie_id: Int
        let planned_date: String
    }

    func addToPlan(movieID: Int, day: PlanDay, userID: String) async throws -> WatchPlanItem {
        try await run {
            try await client.from("watch_plan")
                .insert(PlanInsert(user_id: userID, movie_id: movieID, planned_date: day.description))
                .select("id, user_id, movie_id, planned_date, created_at, movie:movies(*)")
                .single()
                .execute()
                .value
        }
    }

    func movePlanItem(id: Int, to day: PlanDay) async throws {
        try await run {
            try await client.from("watch_plan")
                .update(["planned_date": day.description])
                .eq("id", value: id)
                .execute()
        }
    }

    func removePlanItem(id: Int) async throws {
        try await run {
            try await client.from("watch_plan").delete().eq("id", value: id).execute()
        }
    }

    // MARK: - Groups and leaderboards

    /// RLS shows only the groups you created or belong to.
    func myGroups(userID: String) async throws -> [PoolGroup] {
        try await run {
            try await client.from("groups").select().order("name").execute().value
        }
    }

    private nonisolated struct GroupInsert: Encodable {
        let name: String
        let created_by: String
        let invite_code: String
    }

    /// The creator counts as a member through `groups.created_by`; there is no
    /// `group_members` row to add (Phase 1 removed client inserts there).
    func createGroup(name: String, userID: String) async throws -> PoolGroup {
        try await run {
            try await client.from("groups")
                .insert(GroupInsert(name: name, created_by: userID, invite_code: Self.newInviteCode()))
                .select()
                .single()
                .execute()
                .value
        }
    }

    /// Six characters from an alphabet without look-alikes (no 0/O, 1/I/L).
    static func newInviteCode() -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }

    func joinGroup(inviteCode: String) async throws -> JoinedGroup {
        try await run {
            let rows: [JoinedGroup] = try await client
                .rpc("join_group", params: ["p_invite_code": inviteCode.trimmingCharacters(in: .whitespaces).uppercased()])
                .execute()
                .value
            guard let joined = rows.first else { throw AppError.invalidInviteCode }
            return joined
        }
    }

    func leaveGroup(groupID: Int, userID: String) async throws {
        try await run {
            try await client.from("group_members")
                .delete()
                .eq("group_id", value: groupID)
                .eq("user_id", value: userID)
                .execute()
        }
    }

    func deleteGroup(groupID: Int) async throws {
        try await run {
            try await client.from("groups").delete().eq("id", value: groupID).execute()
        }
    }

    func removeMember(userID: String, groupID: Int) async throws {
        try await run {
            try await client.from("group_members")
                .delete()
                .eq("group_id", value: groupID)
                .eq("user_id", value: userID)
                .execute()
        }
    }

    private nonisolated struct BoardParams: Encodable {
        let p_ceremony_id: Int
        let p_group_id: Int?
    }

    func board(ceremonyID: Int, groupID: Int?) async throws -> [BoardEntry] {
        try await run {
            try await client.rpc("get_leaderboard", params: BoardParams(p_ceremony_id: ceremonyID, p_group_id: groupID)).execute().value
        }
    }

    private nonisolated struct PersonParams: Encodable {
        let p_ceremony_id: Int
        let p_user_id: String
    }

    func boardPerson(ceremonyID: Int, userID: String) async throws -> BoardPerson {
        try await run {
            let rows: [BoardPerson.Row] = try await client
                .rpc("get_board_person", params: PersonParams(p_ceremony_id: ceremonyID, p_user_id: userID))
                .execute()
                .value
            return BoardPerson(rows: rows)
        }
    }

    // MARK: - Push

    private nonisolated struct DeviceParams: Encodable {
        let p_token: String
        let p_environment: String
    }

    func registerDevice(token: String, environment: PushEnvironment) async throws {
        try await run {
            try await client.rpc("register_device", params: DeviceParams(p_token: token, p_environment: environment.rawValue)).execute()
        }
    }

    func removeDevice(token: String) async throws {
        try await run {
            try await client.from("devices").delete().eq("token", value: token).execute()
        }
    }

    // MARK: - Profile

    func profile(userID: String) async throws -> Profile? {
        try await run {
            let rows: [Profile] = try await client.from("profiles").select().eq("id", value: userID).limit(1).execute().value
            return rows.first
        }
    }

    func updateUsername(_ username: String, userID: String) async throws {
        try await run {
            try await client.from("profiles").update(["username": username]).eq("id", value: userID).execute()
        }
    }

    /// Really deletes the account (guideline 5.1.1): `delete_user()` removes the
    /// auth user and, through cascades, every row that belongs to them.
    func account() async -> Account? {
        guard let user = try? await client.auth.session.user else { return nil }
        let provider: Account.Provider = switch user.appMetadata["provider"] {
        case .string("apple"): .apple
        case .string("google"): .google
        default: .email
        }
        return Account(email: user.email, provider: provider)
    }

    func seasonHistory() async throws -> [SeasonResult] {
        try await run {
            try await client.rpc("get_season_history").execute().value
        }
    }

    func revokeApple(authorizationCode: String) async throws {
        try await run {
            try await client.functions.invoke("revoke-apple", options: FunctionInvokeOptions(body: ["authorization_code": authorizationCode]))
        }
    }

    func deleteAccount() async throws {
        try await run {
            try await client.rpc("delete_user").execute()
            try? await client.auth.signOut()
        }
    }
}
