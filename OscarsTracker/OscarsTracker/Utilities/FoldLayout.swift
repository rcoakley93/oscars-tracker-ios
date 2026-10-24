import SwiftUI

/// Layout around the iPhone Duo's fold (screens.md, section 8). System
/// containers (split views, arrangements, sheets) avoid it themselves; a
/// custom layout that spans the inner display reads the fold here, so a
/// grid keeps an even number of columns and a single piece of content sits
/// in one half. Never the device model: no fold, no change.
nonisolated enum FoldLayout {
    /// The fold crossing this view, in its local coordinates. Inactive folds
    /// count too, so nothing jumps as the phone opens past flat.
    static func fold(in proxy: GeometryProxy) -> CGRect? {
        proxy.reservedRegions(kind: .division, options: .includeInactive)
            .map(\.frame)
            .first { !$0.isEmpty && $0.intersects(CGRect(origin: .zero, size: proxy.size)) }
    }

    /// `ideal` columns, made even when a vertical fold crosses the grid, so
    /// no item straddles it. Rounds down (bigger posters), never below 2.
    static func columns(_ ideal: Int, fold: CGRect?) -> Int {
        guard let fold, fold.height >= fold.width, ideal % 2 == 1 else { return ideal }
        return max(2, ideal - 1)
    }

    /// The half of `bounds` beside a vertical fold that has more room, or
    /// all of `bounds` when there's no fold.
    static func roomierHalf(of bounds: CGRect, fold: CGRect?) -> CGRect {
        guard let fold, fold.height >= fold.width else { return bounds }
        let leading = CGRect(x: bounds.minX, y: bounds.minY, width: max(0, fold.minX - bounds.minX), height: bounds.height)
        let trailing = CGRect(x: fold.maxX, y: bounds.minY, width: max(0, bounds.maxX - fold.maxX), height: bounds.height)
        return leading.width >= trailing.width ? leading : trailing
    }
}

extension View {
    /// Centres the view in one half when a vertical fold crosses the space it
    /// was offered, and in the whole space otherwise (the envelope, the podium).
    func centeredBesideFold() -> some View {
        modifier(CenteredBesideFold())
    }
}

private struct CenteredBesideFold: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let half = FoldLayout.roomierHalf(of: CGRect(origin: .zero, size: proxy.size), fold: FoldLayout.fold(in: proxy))
            content
                .frame(width: half.width, height: half.height)
                .offset(x: half.minX, y: half.minY)
        }
    }
}
