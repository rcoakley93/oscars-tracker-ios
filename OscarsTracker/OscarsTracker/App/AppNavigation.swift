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
        case addToPlan(movieID: Int?)

        var id: String {
            switch self {
            case .movie(let id): "movie-\(id)"
            case .profile: "profile"
            case .joinGroup(let code): "join-\(code ?? "")"
            case .createGroup: "create-group"
            case .addToPlan(let id): "add-\(id.map(String.init) ?? "")"
            }
        }
    }

    var tab: Tab = .films
    /// The film shown in the detail pane on wide layouts, or in a sheet on narrow ones.
    var selectedMovieID: Int?
    var selectedCategoryID: Int?
    var selectedDay: PlanDay?
    var selectedGroupID: Int?
    var sheet: Sheet?

    func reset() {
        tab = .films
        selectedMovieID = nil
        selectedCategoryID = nil
        selectedDay = nil
        selectedGroupID = nil
        sheet = nil
    }
}
