import SwiftUI

/// The badge case (screens.md 3.8, P12-04), pushed from Profile › Badges:
/// one section per season, newest first. This season shows every badge,
/// earned in colour and the rest as outlines with how to earn them; past
/// seasons show only what they earned. Gold is only on earned art and tiers.
struct BadgeCaseView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @State private var selected: Selection?

    private struct Selection: Identifiable {
        let tile: BadgeTile
        let season: BadgeSeason
        var id: String { "\(season.id)-\(tile.id)" }
    }

    var body: some View {
        let seasons = model.badgeSeasons
        List {
            if model.badges.mine.isEmpty {
                Section {
                    Text(copy.badgeCaseEmpty).foregroundStyle(.inkMuted)
                }
            }
            ForEach(seasons) { season in
                Section {
                    BadgeGrid(tiles: season.tiles) { selected = Selection(tile: $0, season: season) }
                        .listRowInsets(EdgeInsets(top: Theme.Space.s, leading: Theme.Space.s, bottom: Theme.Space.s, trailing: Theme.Space.s))
                } header: {
                    Text(season.name)
                } footer: {
                    Text("\(season.earnedCount) of \(season.tiles.count) earned")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if seasons.isEmpty, case .failed(let error) = model.badges.state {
                ContentUnavailableView {
                    Label("Couldn't load", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    Button("Try again") { Task { await reload() } }
                }
            }
        }
        .refreshable { await reload() }
        .sheet(item: $selected) { BadgeDetailSheet(tile: $0.tile, seasonName: $0.season.name) }
    }

    private func reload() async {
        guard let userID = model.session.userID else { return }
        await model.badges.load(userID: userID)
    }
}

extension AppModel {
    /// Your badge case: this season (every badge) and the past ones you earned in.
    var badgeSeasons: [BadgeSeason] {
        BadgeSeason.seasons(badges.mine, current: season.ceremony.map { ($0.id, $0.number) })
    }
}

/// An adaptive grid of badge tiles: three across on a phone.
struct BadgeGrid: View {
    let tiles: [BadgeTile]
    var onSelect: ((BadgeTile) -> Void)?
    @ScaledMetric(relativeTo: .body) private var minimum: CGFloat = 96

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: Theme.Space.s, alignment: .top)],
                  spacing: Theme.Space.m) {
            ForEach(tiles) { tile in
                if let onSelect {
                    Button { onSelect(tile) } label: { BadgeTileView(tile: tile) }
                        .buttonStyle(.plain)
                } else {
                    BadgeTileView(tile: tile)
                }
            }
        }
    }
}

/// The art, the name and the tier ("Silver"), or the outline, the name and
/// how to earn it.
struct BadgeTileView: View {
    let tile: BadgeTile
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 64

    var body: some View {
        VStack(spacing: Theme.Space.xxs) {
            BadgeArt(tile: tile, size: size)
                .overlay(alignment: .topTrailing) {
                    if tile.earned.count > 1 {
                        Text(verbatim: "×\(tile.earned.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.goldText)
                            .padding(.horizontal, Theme.Space.xxs)
                            .background(.surface, in: .capsule)
                    }
                }
            Text(tile.badge.name(voice))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tile.isEarned ? .ink : .inkMuted)
                .multilineTextAlignment(.center)
            if let best = tile.best {
                if let tier = tile.badge.tierLabel(best.tier) {
                    Text(tier).font(.caption).foregroundStyle(.goldText)
                }
            } else {
                Text(tile.badge.rule)
                    .font(.caption)
                    .foregroundStyle(.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BadgeArt.label(tile, voice: voice))
        .accessibilityHint(tile.isEarned ? "" : tile.badge.rule)
        .accessibilityAddTraits(.isButton)
    }
}

/// A badge's art from `Badges.xcassets`: its tier earned, the outline not yet.
struct BadgeArt: View {
    let imageName: String
    let size: CGFloat

    init(tile: BadgeTile, size: CGFloat) {
        imageName = tile.imageName
        self.size = size
    }

    init(badge: UserBadge, size: CGFloat) {
        imageName = badge.imageName
        self.size = size
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    /// "Stub Collector, Silver", or "Death Race, not yet earned".
    static func label(_ tile: BadgeTile, voice: Voice) -> String {
        let name = tile.badge.name(voice)
        guard let best = tile.best else { return "\(name), not yet earned" }
        let count = tile.earned.count > 1 ? ", \(tile.earned.count) times" : ""
        return "\(name), \(Badge.tierName(best.tier))\(count)"
    }
}

/// One badge up close: the art, the name and tier, the description, what it
/// names, when it was earned (or how), and Share for an earned one.
struct BadgeDetailSheet: View {
    let tile: BadgeTile
    let seasonName: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Voice.storageKey) private var voice: Voice = .host

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.s) {
                    BadgeArt(tile: tile, size: 160)
                    Text(tile.badge.name(voice))
                        .font(.title2.bold())
                        .foregroundStyle(tile.isEarned ? .ink : .inkMuted)
                        .multilineTextAlignment(.center)
                    if let best = tile.best, let tier = tile.badge.tierLabel(best.tier) {
                        Text(tier).font(.headline).foregroundStyle(.goldText)
                    }
                    Text(tile.badge.description(voice))
                        .font(.body)
                        .foregroundStyle(.ink)
                        .multilineTextAlignment(.center)
                    if let names = model.badgeNames(tile.earned) {
                        Text(names).font(.subheadline).foregroundStyle(.inkMuted).multilineTextAlignment(.center)
                    }
                    Text(status).font(.subheadline).foregroundStyle(.inkMuted).multilineTextAlignment(.center)
                }
                .padding(Theme.Space.l)
                .frame(maxWidth: .infinity)
            }
            .background(.ground)
            .navigationTitle(seasonName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
                .visibilityPriority(.high)
                if let best = tile.best {
                    ToolbarItemGroup(placement: .confirmationAction) {
                        BadgeShareButton(badge: best)
                    }
                    .visibilityPriority(.low)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var status: String {
        guard let best = tile.best else { return "How to earn it: \(tile.badge.rule)." }
        let earned = "Earned \(best.earnedAt.formatted(.dateTime.month(.abbreviated).day()))"
        return [earned, tile.badge.nextTier(after: best.tier)].compactMap(\.self).joined(separator: " · ")
    }
}

extension AppModel {
    /// What earned badges name, as one line: the categories completed, the
    /// groups swept, the groups won. Nil when there's nothing to name.
    func badgeNames(_ rows: [UserBadge]) -> String? {
        guard let first = rows.first else { return nil }
        let names: [String]
        switch first.badgeKey {
        case "top_billing":
            names = rows.compactMap { row in row.detail?.groupId.flatMap { id in groups.groups.first { $0.id == id }?.name } }
        case "category_complete":
            let ids = first.detail?.categoryIds ?? []
            let known = ids.compactMap { id in ballot.categories.first { $0.id == id }?.name }
            names = known.count == ids.count ? known : []
            if names.isEmpty, !ids.isEmpty { return ids.count == 1 ? "1 category" : "\(ids.count) categories" }
        case "category_sweep":
            names = (first.detail?.badgeGroups ?? []).map(Badge.groupName)
        default:
            names = []
        }
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }
}

extension AppModel {
    /// This season's 13 for the strips: earned first, then the outlines,
    /// each in the catalogue's order. All outlines before the season loads.
    var currentBadgeTiles: [BadgeTile] {
        let current = season.ceremony.flatMap { ceremony in badgeSeasons.first { $0.ceremonyId == ceremony.id } }
        let tiles = current?.tiles ?? Badge.catalogue.map { BadgeTile(badge: $0, earned: []) }
        return tiles.filter(\.isEarned) + tiles.filter { !$0.isEarned }
    }
}

/// A row of badge art that never scrolls: as many as fit the width, then
/// "+4". Earned art in colour, the rest as outlines.
struct BadgeStrip: View {
    let tiles: [BadgeTile]
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 32

    /// `size` is the art at the default text size; it grows with Dynamic Type.
    init(tiles: [BadgeTile], size: CGFloat = 32) {
        self.tiles = tiles
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Self.options(tiles.count), id: \.self) { shown in
                HStack(spacing: Theme.Space.xs) {
                    ForEach(tiles.prefix(shown)) { BadgeArt(tile: $0, size: size) }
                    if tiles.count > shown {
                        Text(verbatim: "+\(tiles.count - shown)")
                            .font(.subheadline)
                            .foregroundStyle(.inkMuted)
                            .monospacedDigit()
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// How many to try showing, most first: all, then two fewer each time,
    /// down to three.
    static func options(_ count: Int) -> [Int] {
        guard count > 3 else { return [count] }
        return Array(stride(from: count, through: 3, by: -2)) + (count % 2 == 0 ? [3] : [])
    }

    /// "Badges, 2 of 13 earned: Stub Collector, Silver; Pens Down", or
    /// "Badges, none earned yet".
    static func label(_ tiles: [BadgeTile], voice: Voice) -> String {
        let earned = tiles.filter(\.isEarned)
        guard !earned.isEmpty else { return "Badges, none earned yet" }
        return "Badges, \(earned.count) of \(tiles.count) earned: "
            + earned.map { BadgeArt.label($0, voice: voice) }.joined(separator: "; ")
    }
}

/// Profile's Badges row, right under Account: this season's strip and the
/// count, pushing the case.
struct ProfileBadgesRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @AppStorage(Voice.storageKey) private var voice: Voice = .host

    var body: some View {
        let tiles = model.currentBadgeTiles
        NavigationLink {
            BadgeCaseView()
        } label: {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                BadgeStrip(tiles: tiles)
                Text(copy.badgeCount(tiles.count(where: \.isEarned), tiles.count))
                    .font(.subheadline)
                    .foregroundStyle(.ink)
            }
            .padding(.vertical, Theme.Space.xxs)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BadgeStrip.label(tiles, voice: voice))
        .accessibilityHint("Opens your badge case")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("profile.badges")
    }
}

/// A person's badges on their board page: up to 6, newest first, then "+3".
/// Nothing when they have none or the server won't show them.
struct PersonBadgeRow: View {
    let userID: String
    @Environment(AppModel.self) private var model
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 32
    private static let limit = 6

    var body: some View {
        let loaded = userID == model.session.userID ? model.badges.mine : (model.badges.people[userID] ?? nil) ?? []
        let rows = loaded.filter { $0.badge != nil }.sorted { $0.earnedAt > $1.earnedAt }
        Group {
            if !rows.isEmpty {
                Section("Badges") {
                    HStack(spacing: Theme.Space.xs) {
                        ForEach(rows.prefix(Self.limit), id: \.self) { BadgeArt(badge: $0, size: size) }
                        if rows.count > Self.limit {
                            Text(verbatim: "+\(rows.count - Self.limit)").font(.subheadline).foregroundStyle(.inkMuted)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Badges: " + rows.compactMap { row in
                        row.badge.map { "\($0.name(voice))" + ($0.tierLabel(row.tier).map { ", \($0)" } ?? "") }
                    }.joined(separator: "; "))
                }
                .listRowBackground(Color.surface)
            }
        }
        .task(id: userID) {
            guard userID != model.session.userID else { return }
            await model.badges.loadPerson(userID)
        }
    }
}

#if DEBUG
private struct BadgeCasePreview: View {
    var badges: [UserBadge] = SampleData.myBadges
    var voice = Voice.host

    var body: some View {
        NavigationStack { BadgeCaseView() }
            .environment(\.copy, .for(voice))
            .environment(AppModel.preview { $0.badgeRows[SampleDataSource.userID] = badges })
    }
}

#Preview("Partial") { BadgeCasePreview().preferredColorScheme(.dark) }
#Preview("Empty") { BadgeCasePreview(badges: []).preferredColorScheme(.dark) }
#Preview("Full") { BadgeCasePreview(badges: SampleData.fullBadges).preferredColorScheme(.dark) }
#Preview("Classic") { BadgeCasePreview(voice: .classic).preferredColorScheme(.dark) }
#Preview("Dark") { BadgeCasePreview().preferredColorScheme(.dark) }
#Preview("Light") { BadgeCasePreview().preferredColorScheme(.light) }
#Preview("Large text") { BadgeCasePreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2) }

/// Profile's strip, for none, some and all earned.
private struct BadgeStripsPreview: View {
    var badges: [UserBadge] = SampleData.currentBadges
    var voice = Voice.host

    var body: some View {
        NavigationStack {
            List {
                Section("Badges") { ProfileBadgesRow() }
            }
            .scrollContentBackground(.hidden)
            .background(.ground)
        }
        .environment(\.copy, .for(voice))
        .defaultAppStorage(Self.defaults(voice))
        .environment(AppModel.preview { $0.badgeRows[SampleDataSource.userID] = badges })
    }

    private static func defaults(_ voice: Voice) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "preview.badges.\(voice.rawValue)")!
        defaults.set(voice.rawValue, forKey: Voice.storageKey)
        return defaults
    }
}

#Preview("Strips · None") { BadgeStripsPreview(badges: []).preferredColorScheme(.dark) }
#Preview("Strips · Some") { BadgeStripsPreview().preferredColorScheme(.dark) }
#Preview("Strips · All") { BadgeStripsPreview(badges: SampleData.fullBadges).preferredColorScheme(.dark) }
#Preview("Strips · Classic") { BadgeStripsPreview(voice: .classic).preferredColorScheme(.dark) }
#Preview("Strips · Light") { BadgeStripsPreview().preferredColorScheme(.light) }
#Preview("Strips · Large text") {
    BadgeStripsPreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
#Preview("Detail") {
    Color.ground.sheet(isPresented: .constant(true)) {
        BadgeDetailSheet(tile: BadgeTile(badge: Badge.named("films_watched")!, earned: [SampleData.badge("films_watched", tier: 2)]),
                         seasonName: "99th Academy Awards")
    }
    .environment(AppModel.preview())
}
#endif
