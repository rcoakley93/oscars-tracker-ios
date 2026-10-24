import SwiftUI

/// The line above the tab bar that says where the season is (screens.md,
/// section 2). Text only when the tab bar is minimised (`.inline`); text and,
/// on lock day, a Ballot button when it's `.expanded`. Tapping it opens the
/// matching tab. Gold is for the live and after states, the shell's earned
/// element. The state comes from `SeasonStore` (season facts), on the
/// server's clock.
struct SeasonTicker: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date.addingTimeInterval(model.season.clockOffset)
            let ticker = model.season.ticker(filmsLeft: model.films.toWatch.count, hasNominees: !model.films.movies.isEmpty, now: now)
            let earned = !model.isOffline && (ticker == .live || ticker == .after)
            if let line = model.isOffline ? copy.tickerOffline(model.pending.count) : line(for: ticker, now: now) {
                HStack(spacing: Theme.Space.s) {
                    Button {
                        model.navigation.tab = destination(for: ticker)
                    } label: {
                        Text(line)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(earned ? AnyShapeStyle(.goldOnGlass) : AnyShapeStyle(.primary))
                            .lineLimit(placement == .inline ? 1 : 2)
                            // The whole height of the accessory, not just the line, takes the tap.
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens \(destination(for: ticker).rawValue.capitalized)")
                    .accessibilityIdentifier("season-ticker")

                    if placement != .inline, !model.isOffline, let button = button(for: ticker) {
                        Button(button.title, systemImage: button.symbol) {
                            model.navigation.tab = destination(for: ticker)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, Theme.Space.m)
                // The accessory is one fixed-height line, like the tab bar,
                // so its text stops growing where the bar does and a long
                // press shows the whole line large (Large Content Viewer).
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityShowsLargeContentViewer { Text(line) }
            }
        }
    }

    private func line(for ticker: SeasonStore.Ticker, now: Date) -> String? {
        switch ticker {
        case .none:
            nil
        case .season(let days, let left):
            days <= 7 ? copy.tickerFinalWeek(days, left) : copy.tickerSeason(days, left)
        case .lockDay(let locksAt):
            copy.tickerLockDay(Self.timeLeft(until: locksAt, now: now))
        case .beforeNominations(let date):
            copy.tickerBeforeNominations(date?.formatted(.dateTime.month(.abbreviated).day()))
        case .live:
            copy.tickerLive
        case .after:
            finalStanding
        }
    }

    /// Your place on your first group's board, or the global one.
    private var finalStanding: String? {
        guard let userID = model.session.userID else { return nil }
        let boards = model.groups.groups.map { (Optional($0.id), $0.name) } + [(nil, "everyone")]
        for (groupID, name) in boards {
            if let standing = model.leaderboard.standing(in: groupID, userID: userID, metric: .predictions) {
                return copy.tickerAfter(standing.rank, standing.size, name)
            }
        }
        return nil
    }

    private func button(for ticker: SeasonStore.Ticker) -> (title: String, symbol: String)? {
        switch ticker {
        case .lockDay, .live: ("Ballot", "checkmark.seal")
        case .after: ("Recap", "trophy")
        default: nil
        }
    }

    private func destination(for ticker: SeasonStore.Ticker) -> AppNavigation.Tab {
        switch ticker {
        case .lockDay, .live: .ballot
        case .after: .board
        default: .films
        }
    }

    /// "3 hours", "1 hour", "40 minutes": rounded up, so it never says 0.
    static func timeLeft(until date: Date, now: Date) -> String {
        let minutes = max(1, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
        if minutes < 60 { return minutes == 1 ? "1 minute" : "\(minutes) minutes" }
        let hours = Int((Double(minutes) / 60).rounded())
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}
