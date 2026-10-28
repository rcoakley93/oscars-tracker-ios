import SwiftUI

/// The Board's segments: the two metrics, then Badges (P12-04b), which
/// `AppNavigation` keeps apart from the metric so the other tabs' ranking
/// is untouched.
enum BoardSegment: Hashable {
    case films, predictions, badges

    static func binding(_ navigation: AppNavigation) -> Binding<BoardSegment> {
        Binding {
            navigation.boardShowsBadges ? .badges : navigation.boardMetric == .films ? .films : .predictions
        } set: { segment in
            navigation.boardShowsBadges = segment == .badges
            switch segment {
            case .films: navigation.boardMetric = .films
            case .predictions: navigation.boardMetric = .predictions
            case .badges: break
            }
        }
    }
}

/// The Board's Badges segment (screens.md 3.6): the board's people ranked by
/// badges this season, each with their strip. Your row opens your badge
/// case, anyone else's their page. The global board lists only you and the
/// people in your groups.
struct BadgeBoard: View {
    @Environment(AppModel.self) private var model
    let groupID: Int?

    var body: some View {
        let badges = model.badges
        let entries = badges.board(groupID)
        LoadStateView(state: badges.boardState(groupID), isEmpty: entries.isEmpty) {
            BadgeBoardList(groupID: groupID, entries: entries)
        } placeholder: {
            BadgeBoardList(groupID: groupID, entries: BoardBadgeEntry.placeholders)
        }
        .task(id: BadgeBoardKey(ceremonyID: model.season.ceremony?.id, groupID: groupID)) {
            if badges.boards[groupID] == nil {
                await badges.loadBoard(ceremonyID: model.season.ceremony?.id, groupID: groupID)
            }
        }
    }
}

private struct BadgeBoardKey: Hashable {
    let ceremonyID: Int?
    let groupID: Int?
}

private struct BadgeBoardList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    let groupID: Int?
    let entries: [BoardBadgeEntry]

    var body: some View {
        @Bindable var navigation = model.navigation
        let userID = model.session.userID
        List(selection: $navigation.selectedPersonID) {
            if entries.allSatisfy({ $0.badgeCount == 0 }) {
                Section {
                    Text(copy.boardBadgesEmpty).foregroundStyle(.ink)
                }
                .listRowBackground(Color.surface)
                if let userID {
                    Section("Your badges") {
                        YourBadgeCaseButton { navigation.selectedPersonID = userID }
                    }
                    .listRowBackground(Color.surface)
                }
            } else {
                Section {
                    ForEach(entries) { entry in
                        let isYou = entry.userId == userID
                        BadgeBoardRow(entry: entry, isYou: isYou)
                            .tag(entry.userId)
                            .listRowBackground(Color.surface)
                            .personActions(userID: entry.userId, name: entry.username)
                    }
                } footer: {
                    if groupID == nil {
                        Text("Only people in your groups show here.")
                    }
                }
            }
        }
        .animation(.default, value: entries)
    }
}

/// Rank, avatar, name (gold when it's you), the count and their strip.
struct BadgeBoardRow: View {
    let entry: BoardBadgeEntry
    let isYou: Bool
    @AppStorage(Voice.storageKey) private var voice: Voice = .host

    var body: some View {
        let tiles = entry.tiles
        HStack(alignment: .top, spacing: Theme.Space.s) {
            Text(verbatim: "\(entry.rank)")
                .displayFont(.headline)
                .foregroundStyle(.inkMuted)
                .frame(minWidth: 28, alignment: .leading)
            Avatar(name: entry.username, url: entry.avatarUrl, isYou: isYou)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(isYou ? "You" : entry.username)
                    .font(.body.weight(isYou ? .semibold : .regular))
                    .foregroundStyle(isYou ? AnyShapeStyle(.goldText) : AnyShapeStyle(.ink))
                    .lineLimit(1)
                Text(Self.count(entry.badgeCount))
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if !tiles.isEmpty {
                    BadgeStrip(tiles: tiles, size: 24)
                        .padding(.top, Theme.Space.xxs)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.label(entry, isYou: isYou, voice: voice))
        .accessibilityHint(isYou ? "Opens your badge case" : "Opens their page")
    }

    /// "4 of 13 earned": a fact, the same in both voices.
    static func count(_ count: Int) -> String {
        "\(count) of \(Badge.catalogue.count) earned"
    }

    /// "Number 2, Sam, 4 of 13 badges: Stub Collector, Silver; Pens Down".
    static func label(_ entry: BoardBadgeEntry, isYou: Bool, voice: Voice) -> String {
        let who = "Number \(entry.rank), \(isYou ? "you" : entry.username), \(entry.badgeCount) of \(Badge.catalogue.count) badges"
        let names = entry.tiles.map { BadgeArt.label($0, voice: voice) }
        return names.isEmpty ? who : who + ": " + names.joined(separator: "; ")
    }
}

/// Your outlines and the way into your case, when nobody on the board has a badge.
private struct YourBadgeCaseButton: View {
    @Environment(AppModel.self) private var model
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    let open: () -> Void

    var body: some View {
        let tiles = model.currentBadgeTiles
        Button(action: open) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                BadgeStrip(tiles: tiles)
                Label("Your badge case", systemImage: "chevron.right")
                    .labelStyle(TrailingIcon())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.ink)
            }
            .padding(.vertical, Theme.Space.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your badge case. " + BadgeStrip.label(tiles, voice: voice))
        .accessibilityAddTraits(.isButton)
    }

    private struct TrailingIcon: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: Theme.Space.xxs) {
                configuration.title
                configuration.icon.imageScale(.small)
            }
        }
    }
}

extension BoardBadgeEntry {
    /// Rows for the redacted placeholder while the segment loads.
    static let placeholders: [BoardBadgeEntry] = (1...5).map {
        BoardBadgeEntry(rank: $0, userId: "placeholder-\($0)", username: "Someone", avatarUrl: nil,
                        badgeCount: 6 - $0, badges: [])
    }
}

#if DEBUG
private struct BadgeBoardPreview: View {
    var badges: [String: [UserBadge]] = [SampleDataSource.userID: SampleData.myBadges, "u-sam": SampleData.samBadges]
    var voice = Voice.host

    var body: some View {
        let model = AppModel.preview { $0.badgeRows = badges }
        model.navigation.tab = .board
        model.navigation.boardShowsBadges = true
        return BoardTab()
            .environment(\.copy, .for(voice))
            .environment(model)
    }
}

#Preview("Some earned") { BadgeBoardPreview().preferredColorScheme(.dark) }
#Preview("None earned") { BadgeBoardPreview(badges: [:]).preferredColorScheme(.dark) }
#Preview("All earned") {
    BadgeBoardPreview(badges: [SampleDataSource.userID: SampleData.fullBadges, "u-sam": SampleData.samBadges]).preferredColorScheme(.dark)
}
#Preview("Classic") { BadgeBoardPreview(voice: .classic).preferredColorScheme(.dark) }
#Preview("Dark") { BadgeBoardPreview().preferredColorScheme(.dark) }
#Preview("Light") { BadgeBoardPreview().preferredColorScheme(.light) }
#Preview("Large text") { BadgeBoardPreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2) }
#endif
