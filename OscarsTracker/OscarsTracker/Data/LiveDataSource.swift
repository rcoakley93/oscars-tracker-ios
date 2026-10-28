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

    func seasonFacts() async throws -> SeasonFacts? {
        try await run {
            let rows: [SeasonFacts] = try await client.rpc("get_season_facts").execute().value
            return rows.first
        }
    }

    /// `copy_overrides`' lines with their text in each voice; anything that
    /// isn't a string is skipped.
    nonisolated static func copyOverrides(_ lines: [String: AnyJSON]) -> CopyOverrides {
        lines.compactMapValues { line in
            guard case .object(let voices) = line else { return nil }
            let texts = voices.compactMapValues { if case .string(let text) = $0 { text } else { nil } }
            return texts.isEmpty ? nil : texts
        }
    }

    private nonisolated struct ConfigRow: Decodable {
        let key: String
        let value: AnyJSON
    }

    /// Unknown keys are ignored and malformed values keep their defaults.
    func appConfig() async throws -> AppConfig {
        try await run {
            let rows: [ConfigRow] = try await client.from("app_config").select("key, value").execute().value
            var config = AppConfig.defaults
            for row in rows {
                switch (row.key, row.value) {
                case ("min_supported_build", .integer(let build)):
                    config.minSupportedBuild = build
                case ("min_supported_build", .double(let build)):
                    config.minSupportedBuild = Int(build)
                case ("feature_flags", .object(let flags)):
                    config.featureFlags = flags.compactMapValues { if case .bool(let on) = $0 { on } else { nil } }
                    // The one string flag (2.1); 2.0 drops it with the rest that aren't bools.
                    if case .string(let stage) = flags["list_stage"], let stage = ListStage(rawValue: stage) {
                        config.listStage = stage
                    }
                case ("runtime_buckets", .object(let buckets)):
                    let parsed = RuntimeBucket.parse(buckets.compactMapValues { value in
                        guard case .array(let bounds) = value else { return nil }
                        return bounds.compactMap { if case .integer(let n) = $0 { n } else { nil } }
                    })
                    if !parsed.isEmpty { config.runtimeBuckets = parsed }
                case ("group_member_limit", .integer(let limit)) where limit > 0:
                    config.groupMemberLimit = limit
                case ("user_group_limit", .integer(let limit)) where limit > 0:
                    config.userGroupLimit = limit
                case ("nominations_at", .string(let date)):
                    config.nominationsAt = try? Date(date, strategy: .iso8601)
                case ("copy_overrides", .object(let lines)):
                    config.copyOverrides = Self.copyOverrides(lines)
                default:
                    break
                }
            }
            return config
        }
    }

    // MARK: - Films and watched

    func movies() async throws -> [Movie] {
        try await run {
            try await client.from("movies").select().order("title").execute().value
        }
    }

    /// Named columns: clients can't read the source's own numbers (P9-01).
    func contenders() async throws -> [Contender] {
        try await run {
            try await client.rpc("get_contenders").execute().value
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

    /// The active ceremony's categories (the rehearsal for testers). Every
    /// ceremony whose nominations are announced is visible, so on nominations
    /// day the 98th's would otherwise come too (P9-05).
    func ballot() async throws -> [BallotCategory] {
        try await run {
            let facts: [SeasonFacts] = try await client.rpc("get_season_facts").execute().value
            var categoryQuery = client.from("categories").select()
            if let ceremonyID = facts.first?.id { categoryQuery = categoryQuery.eq("ceremony_id", value: ceremonyID) }
            let categories: [Category] = try await categoryQuery
                .order("points_value", ascending: false)
                .order("name")
                .execute()
                .value
            guard !categories.isEmpty else { return [] }
            let nominations: [NominationRow] = try await client.from("nominations")
                .select("id, category_id, detail_text, is_winner, movie:movies(*)")
                .in("category_id", values: categories.map(\.id))
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
                        .sorted { ($0.personName ?? $0.movie?.title ?? "") < ($1.personName ?? $1.movie?.title ?? "") },
                    displayMode: category.displayMode,
                    ceremonyID: category.ceremonyId
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

    private nonisolated struct SharesParams: Encodable {
        let p_ceremony_id: Int
        let p_group_id: Int
    }

    func pickShares(ceremonyID: Int, groupID: Int) async throws -> [PickShare] {
        try await run {
            try await client.rpc("get_group_pick_shares", params: SharesParams(p_ceremony_id: ceremonyID, p_group_id: groupID)).execute().value
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
                // One row per film: planning a film that's already planned moves it.
                .upsert(PlanInsert(user_id: userID, movie_id: movieID, planned_date: day.description), onConflict: "user_id,movie_id")
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

    // MARK: - Live Activity (P6-03)

    private nonisolated struct LiveActivityParams: Encodable {
        let p_ceremony_id: Int
        let p_token: String
        let p_environment: String
    }

    private nonisolated struct TokenParams: Encodable {
        let p_token: String
    }

    func registerLiveActivity(ceremonyID: Int, token: String, environment: PushEnvironment) async throws {
        try await run {
            try await client.rpc("register_live_activity",
                                 params: LiveActivityParams(p_ceremony_id: ceremonyID, p_token: token, p_environment: environment.rawValue))
                .execute()
        }
    }

    func endLiveActivity(ceremonyID: Int) async throws {
        try await run {
            try await client.rpc("end_live_activity", params: CeremonyParams(p_ceremony_id: ceremonyID)).execute()
        }
    }

    func registerLiveActivityStartToken(_ token: String, environment: PushEnvironment) async throws {
        try await run {
            try await client.rpc("register_live_activity_start_token",
                                 params: DeviceParams(p_token: token, p_environment: environment.rawValue))
                .execute()
        }
    }

    func removeLiveActivityStartToken(_ token: String) async throws {
        try await run {
            try await client.rpc("remove_live_activity_start_token", params: TokenParams(p_token: token)).execute()
        }
    }

    private nonisolated struct PreferencesParams: Encodable {
        let p_nominations: Bool
        let p_watch_plan: Bool
        let p_ballot_lock: Bool
        let p_results: Bool
        let p_voice: String
        let p_time_zone: String
    }

    func notificationPreferences(userID: String) async throws -> NotificationPreferences? {
        try await run {
            let rows: [NotificationPreferences] = try await client.from("notification_preferences")
                .select().eq("user_id", value: userID).limit(1).execute().value
            return rows.first
        }
    }

    func saveNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        try await run {
            try await client.rpc("save_notification_preferences", params: PreferencesParams(
                p_nominations: preferences.nominations, p_watch_plan: preferences.watchPlan,
                p_ballot_lock: preferences.ballotLock, p_results: preferences.results,
                p_voice: preferences.voice, p_time_zone: preferences.timeZone
            )).single().execute().value
        }
    }

    // MARK: - Admin

    private nonisolated struct WinnerParams: Encodable {
        let p_nomination_id: Int
        let p_tie: Bool
    }

    private nonisolated struct WinnersParams: Encodable {
        let p_category_id: Int
        let p_nomination_ids: [Int]
    }

    private nonisolated struct CeremonyDatesParams: Encodable {
        let p_ceremony_id: Int
        let p_ceremony_at: Date
        let p_ballot_lock_at: Date
    }

    private nonisolated struct PushParams: Encodable {
        let p_title: String
        let p_body: String
        let p_path: String
    }

    func adminStatus() async throws -> [AdminCeremony] {
        try await run {
            try await client.rpc("admin_status").execute().value
        }
    }

    /// In `ceremony_order`, else the small categories first and Best Picture last.
    func adminBallot(ceremonyID: Int) async throws -> [BallotCategory] {
        try await run {
            let categories: [Category] = try await client.from("categories")
                .select()
                .eq("ceremony_id", value: ceremonyID)
                .order("ceremony_order", ascending: true, nullsFirst: false)
                .order("points_value", ascending: true)
                .order("name")
                .execute()
                .value
            guard !categories.isEmpty else { return [] }
            let nominations: [NominationRow] = try await client.from("nominations")
                .select("id, category_id, detail_text, is_winner, movie:movies(*)")
                .in("category_id", values: categories.map(\.id))
                .order("id")
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
                )
            }
        }
    }

    func setWinner(nominationID: Int, tie: Bool) async throws -> Set<Int> {
        try await run {
            let winners: [Int] = try await client.rpc("admin_set_winner", params: WinnerParams(p_nomination_id: nominationID, p_tie: tie)).execute().value
            return Set(winners)
        }
    }

    func clearWinners(categoryID: Int) async throws {
        try await run {
            try await client.rpc("admin_clear_winners", params: ["p_category_id": categoryID]).execute()
        }
    }

    func setWinners(categoryID: Int, nominationIDs: Set<Int>) async throws -> Set<Int> {
        try await run {
            let winners: [Int] = try await client.rpc("admin_set_winners", params: WinnersParams(p_category_id: categoryID, p_nomination_ids: nominationIDs.sorted())).execute().value
            return Set(winners)
        }
    }

    func setActiveCeremony(id: Int) async throws {
        try await run {
            try await client.rpc("admin_set_active_ceremony", params: ["p_ceremony_id": id]).execute()
        }
    }

    func setCeremonyDates(id: Int, ceremonyAt: Date, ballotLockAt: Date) async throws {
        try await run {
            try await client.rpc("admin_set_ceremony_dates", params: CeremonyDatesParams(p_ceremony_id: id, p_ceremony_at: ceremonyAt, p_ballot_lock_at: ballotLockAt)).execute()
        }
    }

    func sendPushToEveryone(title: String, body: String, destination: PushDestination) async throws {
        try await run {
            try await client.rpc("admin_send_push", params: PushParams(p_title: title, p_body: body, p_path: destination.rawValue)).execute()
        }
    }

    private nonisolated struct CeremonyParams: Encodable {
        let p_ceremony_id: Int
    }

    func sendNominationsPush(ceremonyID: Int) async throws -> Int {
        try await run {
            try await client.rpc("admin_send_nominations_push", params: CeremonyParams(p_ceremony_id: ceremonyID)).execute().value
        }
    }

    // MARK: - Moderation (P6-16)

    private nonisolated struct ReportUserParams: Encodable {
        let p_user_id: String
        let p_reason: String
        let p_details: String?
    }

    private nonisolated struct ReportGroupParams: Encodable {
        let p_group_id: Int
        let p_reason: String
        let p_details: String?
    }

    private nonisolated struct ResolveParams: Encodable {
        let p_report_id: Int
        let p_action: String
    }

    func reportUser(_ userID: String, reason: ReportReason, details: String?) async throws {
        try await run {
            try await client.rpc("report_user", params: ReportUserParams(p_user_id: userID, p_reason: reason.rawValue, p_details: details)).execute()
        }
    }

    func reportGroup(_ groupID: Int, reason: ReportReason, details: String?) async throws {
        try await run {
            try await client.rpc("report_group", params: ReportGroupParams(p_group_id: groupID, p_reason: reason.rawValue, p_details: details)).execute()
        }
    }

    func blockUser(_ userID: String) async throws {
        try await run {
            try await client.rpc("block_user", params: ["p_user_id": userID]).execute()
        }
    }

    func unblockUser(_ userID: String) async throws {
        try await run {
            try await client.rpc("unblock_user", params: ["p_user_id": userID]).execute()
        }
    }

    func blockedUsers() async throws -> [BlockedUser] {
        try await run {
            try await client.rpc("get_blocked_users").execute().value
        }
    }

    func adminReports() async throws -> [ContentReport] {
        try await run {
            try await client.rpc("admin_reports").execute().value
        }
    }

    func resolveReport(id: Int, action: ReportAction) async throws -> Int {
        try await run {
            try await client.rpc("admin_resolve_report", params: ResolveParams(p_report_id: id, p_action: action.rawValue)).execute().value
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

    private nonisolated struct ArchiveParams: Encodable {
        let p_ceremony_id: Int
    }

    func seasonArchive(ceremonyID: Int) async throws -> SeasonArchive {
        try await run {
            try await client.rpc("get_season_archive", params: ArchiveParams(p_ceremony_id: ceremonyID)).execute().value
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

    // MARK: - Live mode

    private nonisolated struct WinnerRow: Decodable {
        let id: Int
        let category_id: Int?
        let is_winner: Bool?
    }

    /// Updates to `nominations` from Realtime. The server applies the table's
    /// select policy, so a tester hears the rehearsal and everyone else the
    /// real ceremony. The client rejoins the channel itself after a drop;
    /// what changed meanwhile comes in with the next refresh.
    func winnerUpdates() -> AsyncStream<WinnerUpdate> {
        let client = client
        let channel = client.channel("live-winners")
        let changes = channel.postgresChange(UpdateAction.self, schema: "public", table: "nominations")
        return AsyncStream { continuation in
            let task = Task {
                do {
                    try await channel.subscribeWithError()
                } catch {
                    continuation.finish()
                    return
                }
                for await change in changes {
                    guard let row = try? change.decodeRecord(as: WinnerRow.self, decoder: JSONDecoder()),
                          let categoryID = row.category_id else { continue }
                    continuation.yield(WinnerUpdate(nominationID: row.id, categoryID: categoryID, isWinner: row.is_winner ?? false))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await client.removeChannel(channel) }
            }
        }
    }
}
