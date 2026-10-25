import ActivityKit
import Foundation
import Observation

/// The ceremony on the Lock Screen and in the Dynamic Island (P6-03), on
/// while `app_config.feature_flags.live_activity` is.
///
/// It starts from the hero's "Follow the ceremony" button, or by
/// push-to-start when the first winner is set. Each activity's push token
/// goes to the server, and `send-push` updates it whenever the admin sets a
/// winner, so it keeps up while the app is closed. While the app is open,
/// live mode's winners update it at once too.
@Observable
final class LiveActivityStore {
    /// An activity for the active ceremony is running.
    private(set) var isFollowing = false
    var actionError: AppError?

    private let data: any AppDataSource
    /// Whether the system lets this app run Live Activities; replaced in tests.
    private let activitiesEnabled: () -> Bool
    /// Token and state observers, by activity id.
    private var observers: [String: Task<Void, Never>] = [:]
    private var listening: Task<Void, Never>?
    private var startToken: String?
    /// Tokens the server hasn't confirmed (offline, or a failed call), by
    /// ceremony; sent again on the next refresh.
    private(set) var unsentTokens: [Int: String] = [:]
    private var startTokenUnsent = false
    private var ceremonyID: Int?

    init(data: any AppDataSource, activitiesEnabled: @escaping () -> Bool = { ActivityAuthorizationInfo().areActivitiesEnabled }) {
        self.data = data
        self.activitiesEnabled = activitiesEnabled
    }

    private var activities: [Activity<CeremonyActivityAttributes>] {
        Activity<CeremonyActivityAttributes>.activities.filter { ceremonyID == nil || $0.attributes.ceremonyID == ceremonyID }
    }

    /// Whether the Follow button shows: the flag is on and the system allows
    /// Live Activities. On the hero, ceremony night only.
    func canFollow(config: AppConfig) -> Bool {
        config.isEnabled(AppConfig.liveActivity) && activitiesEnabled()
    }

    // MARK: - Following

    /// At launch and after sign-in, while the flag is on: picks up activities
    /// already running (or started by push while the app was closed) and
    /// saves the push-to-start token.
    func start(ceremonyID: Int?) {
        self.ceremonyID = ceremonyID
        for activity in activities { observe(activity) }
        refreshFollowing()
        guard listening == nil else { return }
        listening = Task { [weak self] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await activity in Activity<CeremonyActivityAttributes>.activityUpdates {
                        await self?.adopt(activity)
                    }
                }
                group.addTask { [weak self] in
                    for await token in Activity<CeremonyActivityAttributes>.pushToStartTokenUpdates {
                        await self?.saveStartToken(token)
                    }
                }
            }
        }
    }

    /// Starts the activity for the active ceremony, or updates the one running.
    func follow(ceremony: Ceremony, voice: Voice, state: CeremonyActivityAttributes.ContentState) async {
        ceremonyID = ceremony.id
        guard activitiesEnabled() else {
            actionError = .liveActivitiesOff
            return
        }
        if !activities.isEmpty {
            await update(state)
            return
        }
        let attributes = CeremonyActivityAttributes(ceremonyID: ceremony.id, ceremonyName: ceremony.name, voice: voice.rawValue)
        do {
            let activity = try Activity.request(attributes: attributes, content: content(state), pushType: .token)
            observe(activity)
            isFollowing = true
        } catch {
            actionError = .liveActivitiesOff
        }
    }

    /// New winners while the app is open; the server's push brings the same.
    /// When the app doesn't know which winner came last (a cold start: the
    /// ballot isn't in announcement order), each activity keeps the winner
    /// it shows, which a push put there, and takes only the figures.
    func update(_ state: CeremonyActivityAttributes.ContentState, knowsLatest: Bool = true) async {
        for activity in activities {
            let next = knowsLatest ? state : Self.keepingWinner(of: activity.content.state, in: state)
            if next.isFinished {
                await activity.end(content(next), dismissalPolicy: .after(.now.addingTimeInterval(2 * 60 * 60)))
            } else {
                await activity.update(content(next))
            }
        }
    }

    /// `state`'s figures under `shown`'s winner, when it shows one.
    nonisolated static func keepingWinner(of shown: CeremonyActivityAttributes.ContentState,
                                          in state: CeremonyActivityAttributes.ContentState) -> CeremonyActivityAttributes.ContentState {
        guard shown.category != nil else { return state }
        var next = state
        next.category = shown.category
        next.winner = shown.winner
        next.detail = shown.detail
        next.outcome = shown.outcome
        return next
    }

    /// On each refresh (launch, the network back, the foreground): tokens
    /// that didn't reach the server go again.
    func sendUnsentTokens() async {
        for (ceremonyID, token) in unsentTokens.sorted(by: { $0.key < $1.key }) {
            await register(token, ceremonyID: ceremonyID)
        }
        if startTokenUnsent, let startToken { await registerStartToken(startToken) }
    }

    /// Saves an activity's token, keeping it to retry if that fails. Offline
    /// is expected and silent; anything else shows.
    func register(_ token: String, ceremonyID: Int) async {
        unsentTokens[ceremonyID] = token
        do {
            try await data.registerLiveActivity(ceremonyID: ceremonyID, token: token, environment: .current)
            if unsentTokens[ceremonyID] == token { unsentTokens[ceremonyID] = nil }
        } catch {
            let error = AppError(error)
            if error != .offline { actionError = error }
        }
    }

    private func registerStartToken(_ token: String) async {
        startTokenUnsent = true
        do {
            try await data.registerLiveActivityStartToken(token, environment: .current)
            if startToken == token { startTokenUnsent = false }
        } catch {
            // Push-to-start is a bonus; the next refresh tries again.
        }
    }

    /// Sign-out or a deleted account: ends every activity and forgets the
    /// push-to-start token, so the next person on this phone isn't followed.
    /// (The flag going off doesn't end one: a config that failed to load
    /// reads as off, and the server stops sending anyway.)
    func stop() async {
        listening?.cancel()
        listening = nil
        for task in observers.values { task.cancel() }
        observers = [:]
        for activity in Activity<CeremonyActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        isFollowing = false
        unsentTokens = [:]
        startTokenUnsent = false
        if let startToken {
            try? await data.removeLiveActivityStartToken(startToken)
            self.startToken = nil
        }
    }

    private func content(_ state: CeremonyActivityAttributes.ContentState) -> ActivityContent<CeremonyActivityAttributes.ContentState> {
        // Stale after an hour without news: the show has a long middle.
        ActivityContent(state: state, staleDate: .now.addingTimeInterval(60 * 60))
    }

    private func adopt(_ activity: Activity<CeremonyActivityAttributes>) {
        observe(activity)
        refreshFollowing()
    }

    private func refreshFollowing() {
        isFollowing = activities.contains { $0.activityState == .active || $0.activityState == .stale }
    }

    /// Sends each push token as it arrives and tells the server when the
    /// activity ends, so it stops sending.
    private func observe(_ activity: Activity<CeremonyActivityAttributes>) {
        guard observers[activity.id] == nil else { return }
        let ceremonyID = activity.attributes.ceremonyID
        observers[activity.id] = Task { [weak self, data] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await token in activity.pushTokenUpdates {
                        await self?.register(Self.hex(token), ceremonyID: ceremonyID)
                    }
                }
                group.addTask { [weak self] in
                    for await state in activity.activityStateUpdates {
                        await self?.refreshFollowing()
                        if state == .dismissed || state == .ended {
                            await self?.dropUnsent(ceremonyID)
                            try? await data.endLiveActivity(ceremonyID: ceremonyID)
                            await self?.forget(activity.id)
                            return
                        }
                    }
                }
            }
        }
    }

    private func dropUnsent(_ ceremonyID: Int) {
        unsentTokens[ceremonyID] = nil
    }

    private func forget(_ id: String) {
        observers[id]?.cancel()
        observers[id] = nil
    }

    private func saveStartToken(_ token: Data) async {
        let hex = Self.hex(token)
        startToken = hex
        await registerStartToken(hex)
    }

    nonisolated static func hex(_ token: Data) -> String {
        token.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Content

extension LiveActivityStore {
    /// What the activity shows, from the ballot, the global board and the
    /// category that last gained a winner. The score follows the global
    /// board's rule, as the server's pushes do.
    static func state(categories: [BallotCategory], picks: [Int: Int], latestCategoryID: Int?,
                      board: [BoardEntry], userID: String?) -> CeremonyActivityAttributes.ContentState {
        let decided = categories.filter { !$0.winnerIDs.isEmpty }
        let me = board.first { $0.userId == userID }
        let correct = decided.filter { category in picks[category.id].map(category.winnerIDs.contains) == true }
        let score = me?.scoring == .weighted ? correct.reduce(0) { $0 + $1.pointsValue } : correct.count

        var state = CeremonyActivityAttributes.ContentState(decided: decided.count, total: categories.count, score: score,
                                                            rank: me?.rank, players: me == nil ? nil : board.count)
        let latest = decided.first { $0.id == latestCategoryID } ?? decided.last
        guard let latest else { return state }
        let winners = latest.nominations.filter(\.isWinner)
        state.category = latest.name
        state.winner = winners.compactMap { $0.title(in: latest) }.formatted(.list(type: .and))
        let details = winners.compactMap { $0.detail(in: latest) }
        state.detail = latest.leadsWithPerson && !details.isEmpty ? details.formatted(.list(type: .and)) : nil
        state.outcome = picks[latest.id].map { latest.winnerIDs.contains($0) ? .correct : .wrong }
        return state
    }
}

/// ActivityKit's handle is a reference to system state that's safe to use
/// from any task, but the SDK doesn't mark it `Sendable`, and Swift 6 won't
/// pass it to its own async methods without this.
extension Activity: @retroactive @unchecked Sendable {}
