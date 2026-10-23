import SwiftUI

/// The haptic for each moment (P3-08), the same map the web app defined.
enum Moment {
    case pick, watched, unwatched, ballotComplete, allWatched, joinedGroup, envelopeOpen, correct, wrong, ballotLocked

    var feedback: SensoryFeedback {
        switch self {
        case .pick, .unwatched: .selection
        case .watched: .impact(weight: .light)
        case .ballotComplete, .allWatched, .joinedGroup, .correct: .success
        case .envelopeOpen: .impact(weight: .medium)
        case .wrong: .warning
        case .ballotLocked: .impact(weight: .heavy)
        }
    }
}

extension View {
    /// Plays the moment's haptic whenever `trigger` changes.
    func moment<T: Equatable>(_ moment: Moment, trigger: T) -> some View {
        sensoryFeedback(moment.feedback, trigger: trigger)
    }
}
