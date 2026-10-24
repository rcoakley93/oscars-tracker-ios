import SwiftUI

// The iPhone Duo arrived with iOS 27.1, and so did its APIs. The app runs
// from iOS 27.0 (so phones not yet on 27.1 can test it), so each Duo API
// used here sits behind one of these, and does nothing, or the plain
// equivalent, before 27.1.

extension View {
    /// On the Duo's outer display, keeps a task screen's bar actions over
    /// the tab bar when space is short (screens.md, section 8).
    @ViewBuilder
    func prefersToolbarItemsWhenCompressed() -> some View {
        if #available(iOS 27.1, *) {
            toolbarVerticalCompressionBehavior(.prefersToolbarItems)
        } else {
            self
        }
    }

    /// How far a Duo is open while it's part open, from 0 (shut) to 1
    /// (flat), or nil when it isn't part open or there's no hinge.
    func onHingeOpenness(isEnabled: Bool, perform action: @escaping (Double?) -> Void) -> some View {
        modifier(HingeOpenness(isEnabled: isEnabled, action: action))
    }
}

private struct HingeOpenness: ViewModifier {
    let isEnabled: Bool
    let action: (Double?) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.onHingeChange(isEnabled: isEnabled) { _, context in
                guard let hinge = context.hinge, hinge.status == .partiallyOpen else { return action(nil) }
                action(min(max(hinge.angle.degrees / 180, 0), 1))
            }
        } else {
            content
        }
    }
}

/// Two views with no navigation between them, side by side: an
/// `ArrangementView` in the split style from iOS 27.1, two columns before it.
struct SplitArrangement<Primary: View, Secondary: View>: View {
    @ViewBuilder var primary: Primary
    @ViewBuilder var secondary: Secondary

    var body: some View {
        if #available(iOS 27.1, *) {
            ArrangementView { primary } secondary: { secondary }
                .arrangementViewStyle(.split)
        } else {
            HStack(spacing: 0) {
                primary.frame(maxWidth: .infinity)
                Divider()
                secondary.frame(maxWidth: .infinity)
            }
        }
    }
}
