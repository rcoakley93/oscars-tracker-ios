import ActivityKit
import SwiftUI
import WidgetKit

/// Ceremony night on the Lock Screen and in the Dynamic Island (P6-03,
/// screens.md section 5): the latest winner, how many categories are done,
/// your score and your rank. Your score is the gold.
///
/// The compact forms stay short ("12/23" and the trophy): on the iPhone
/// Duo's outer display the camera region widens into the island, which
/// leaves less room on either side.
struct CeremonyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CeremonyActivityAttributes.self) { context in
            LockScreenBanner(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(.surface)
                .activitySystemActionForegroundColor(.ink)
        } dynamicIsland: { context in
            let copy = LiveActivityCopy(voice: context.attributes.voice)
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(.gold)
                        .accessibilityHidden(true)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ScoreFigure(state: state, copy: copy, style: .title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(state.category ?? context.attributes.ceremonyName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    WinnerLines(state: state, copy: copy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.gold)
                    .accessibilityLabel(context.attributes.ceremonyName)
            } compactTrailing: {
                Text(LiveActivityCopy.progress(state))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .accessibilityLabel(copy.progressLine(state))
            } minimal: {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.gold)
                    .accessibilityLabel(copy.progressLine(state))
            }
            .keylineTint(.gold)
        }
    }
}

/// The Lock Screen form: a solid banner, the winner in display type and your
/// score in gold.
struct LockScreenBanner: View {
    let attributes: CeremonyActivityAttributes
    let state: CeremonyActivityAttributes.ContentState

    var body: some View {
        let copy = LiveActivityCopy(voice: attributes.voice)
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(alignment: .top, spacing: Theme.Space.m) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text(state.category ?? attributes.ceremonyName)
                        .font(.footnote.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.inkMuted)
                        .lineLimit(1)
                    WinnerLines(state: state, copy: copy)
                }
                Spacer(minLength: 0)
                ScoreFigure(state: state, copy: copy, style: .title)
            }
            ProgressView(value: Double(state.decided), total: Double(max(state.total, 1))) {
                Text(copy.progressLine(state))
                    .font(.caption)
                    .foregroundStyle(.inkMuted)
            }
            .tint(.gold)
        }
        .padding(Theme.Space.m)
        .foregroundStyle(.ink)
    }
}

/// The winner, the film under a person, and whether you called it.
private struct WinnerLines: View {
    let state: CeremonyActivityAttributes.ContentState
    let copy: LiveActivityCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let winner = state.winner {
                Text(winner)
                    .displayFont(.headline)
                    .lineLimit(2)
                if let detail = state.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                        .lineLimit(1)
                }
                if let line = copy.outcome(state.outcome) {
                    Label(line, systemImage: state.outcome == .correct ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(state.outcome == .correct ? Color.success : Color.inkMuted)
                }
            } else {
                Text(copy.waiting)
                    .displayFont(.headline)
                    .lineLimit(2)
            }
        }
    }
}

/// Your score, the earned gold, with your place under it.
private struct ScoreFigure: View {
    let state: CeremonyActivityAttributes.ContentState
    let copy: LiveActivityCopy
    let style: Font.TextStyle

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(state.score, format: .number)
                .displayFont(style)
                .monospacedDigit()
                .foregroundStyle(Theme.goldGradient)
                .contentTransition(.numericText(value: Double(state.score)))
            if let rank = copy.rank(state) {
                Text(rank)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel([copy.score(state.score), copy.rank(state)].compactMap(\.self).joined(separator: ", "))
    }
}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: CeremonyActivityAttributes.preview) {
    CeremonyLiveActivity()
} contentStates: {
    CeremonyActivityAttributes.ContentState.previewWaiting
    CeremonyActivityAttributes.ContentState.previewCalled
    CeremonyActivityAttributes.ContentState.previewMissed
    CeremonyActivityAttributes.ContentState.previewFinal
}

#Preview("Compact", as: .dynamicIsland(.compact), using: CeremonyActivityAttributes.preview) {
    CeremonyLiveActivity()
} contentStates: {
    CeremonyActivityAttributes.ContentState.previewCalled
    CeremonyActivityAttributes.ContentState.previewFinal
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: CeremonyActivityAttributes.preview) {
    CeremonyLiveActivity()
} contentStates: {
    CeremonyActivityAttributes.ContentState.previewCalled
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: CeremonyActivityAttributes.preview) {
    CeremonyLiveActivity()
} contentStates: {
    CeremonyActivityAttributes.ContentState.previewWaiting
    CeremonyActivityAttributes.ContentState.previewCalled
    CeremonyActivityAttributes.ContentState.previewMissed
}

#Preview("Classic", as: .content, using: CeremonyActivityAttributes(ceremonyID: 99, ceremonyName: "99th Academy Awards", voice: "classic")) {
    CeremonyLiveActivity()
} contentStates: {
    CeremonyActivityAttributes.ContentState.previewCalled
    CeremonyActivityAttributes.ContentState.previewFinal
}

#Preview("Lock Screen, Light", traits: .fixedLayout(width: 370, height: 160)) {
    LockScreenBanner(attributes: .preview, state: .previewCalled)
        .background(.surface)
        .preferredColorScheme(.light)
}

#Preview("Lock Screen, Large text", traits: .fixedLayout(width: 370, height: 260)) {
    LockScreenBanner(attributes: .preview, state: .previewCalled)
        .background(.surface)
        .dynamicTypeSize(.accessibility2)
}
