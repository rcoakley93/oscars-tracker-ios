import SwiftUI

/// The line above the tab bar that says where the season is (screens.md,
/// section 2). Text only when the tab bar is minimised (`.inline`); text and,
/// on lock day, a Ballot button when it's `.expanded`. Tapping it opens the
/// matching tab. Gold is for the live and after states (P4-10), so none here.
struct SeasonTicker: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        TimelineView(.everyMinute) { context in
            let ticker = model.season.ticker(filmsLeft: model.films.toWatch.count, now: context.date)
            if let line = line(for: ticker, now: context.date) {
                HStack(spacing: Theme.Space.s) {
                    Button {
                        model.navigation.tab = destination(for: ticker)
                    } label: {
                        Text(line)
                            .font(.footnote.weight(.medium))
                            .lineLimit(placement == .inline ? 1 : 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens \(destination(for: ticker).rawValue.capitalized)")

                    if placement != .inline, case .lockDay = ticker {
                        Button("Ballot", systemImage: "checkmark.seal") {
                            model.navigation.tab = .ballot
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
        }
    }

    private func destination(for ticker: SeasonStore.Ticker) -> AppNavigation.Tab {
        if case .lockDay = ticker { .ballot } else { .films }
    }

    /// "3 hours", "1 hour", "40 minutes": rounded up, so it never says 0.
    static func timeLeft(until date: Date, now: Date) -> String {
        let minutes = max(1, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
        if minutes < 60 { return minutes == 1 ? "1 minute" : "\(minutes) minutes" }
        let hours = Int((Double(minutes) / 60).rounded())
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}
