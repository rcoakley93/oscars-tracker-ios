import Foundation
import Observation

/// Where you are in the app. It lives in the model, not in views, so folding
/// or unfolding an iPhone Duo (a size-class change that rebuilds the layout)
/// keeps the selected tab, the open film or category and any sheet.
@Observable
final class AppNavigation {
    enum Tab: String, CaseIterable, Identifiable {
        case films, plan, ballot, board, groups
        var id: String { rawValue }
    }

    enum Sheet: Identifiable, Equatable {
        case movie(Int)
        case profile
        case joinGroup(code: String?)
        case createGroup
        /// Plan: pick a film for this day.
        case addToDay(PlanDay)
        /// Plan: move this plan item to another day.
        case reschedule(itemID: Int)
        case whatCanIWatch
        case fillPlan
        /// Films and nominees by name, from the Films toolbar.
        case search
        /// The ballot or score as an image to share (P6-08).
        case shareCard
        /// The results recap, after the show (P6-10).
        case recap
        /// Report a person or a group (P6-16).
        case report(ReportTarget)
        /// The list moved to a new stage (P10-03).
        case stageMoment

        var id: String {
            switch self {
            case .movie(let id): "movie-\(id)"
            case .profile: "profile"
            case .joinGroup(let code): "join-\(code ?? "")"
            case .createGroup: "create-group"
            case .addToDay(let day): "add-day-\(day)"
            case .reschedule(let id): "reschedule-\(id)"
            case .whatCanIWatch: "what-can-i-watch"
            case .fillPlan: "fill-plan"
            case .search: "search"
            case .shareCard: "share-card"
            case .recap: "recap"
            case .report(let target): "report-\(target.id)"
            case .stageMoment: "stage-moment"
            }
        }
    }

    var tab: Tab = .films
    /// The film shown in the detail pane on wide layouts, or in a sheet on narrow ones.
    var selectedMovieID: Int?
    var selectedCategoryID: Int?
    var selectedDay: PlanDay?
    var selectedGroupID: Int?
    /// The group whose picks the Ballot shows after the lock; nil is your first group.
    var ballotGroupID: Int?
    /// The Board's group; nil is the global board.
    var boardGroupID: Int?
    var boardMetric: LeaderboardStore.Metric = .films
    /// The person whose picks or watched films the Board shows on wide layouts.
    var selectedPersonID: String?
    var sheet: Sheet?
    /// A film's detail is open as a sheet from Films (compact width), which
    /// `sheet` doesn't hold; Films keeps it current. Moments wait for it.
    var isFilmSheetOpen = false
    /// The search sheet's query, kept across a fold like everything else here.
    var searchText = ""
    #if DEBUG
    /// A debug gallery opened from launch arguments for screenshots ("tokens", "moments").
    var debugGallery: String?
    #endif

    /// Opens an in-app route from a notification (send-push's `path`):
    /// "/ballot", "/movie/12", "/category/3", "/group/4". Unknown routes open
    /// the app as it was.
    func open(path: String) {
        let parts = path.split(separator: "/").map(String.init)
        guard let first = parts.first else { return }
        let id = parts.dropFirst().first.flatMap { Int($0) }
        switch (first, id) {
        case ("movie", let id?):
            sheet = .movie(id)
        case ("category", let id?):
            tab = .ballot
            selectedCategoryID = id
        case ("group", let id?):
            tab = .groups
            selectedGroupID = id
        default:
            if let tab = Tab(rawValue: first) { self.tab = tab }
        }
    }

    func reset() {
        tab = .films
        selectedMovieID = nil
        selectedCategoryID = nil
        selectedDay = nil
        selectedGroupID = nil
        ballotGroupID = nil
        boardGroupID = nil
        boardMetric = .films
        selectedPersonID = nil
        sheet = nil
        searchText = ""
    }
}
