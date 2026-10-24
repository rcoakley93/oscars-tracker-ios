import SwiftUI

// The tabs here are the shell's placeholder screens (P3-05, P3-10). They use
// the real stores in plain system lists styled with the tokens, laid out in
// the containers the finished screens use. Phase 4 replaces each one.

/// Shows a store's loading and error states around its content.
struct LoadStateView<Content: View>: View {
    let state: LoadState
    let isEmpty: Bool
    var empty: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView>? = nil
    @ViewBuilder var content: Content
    @Environment(AppModel.self) private var model

    var body: some View {
        if isEmpty, state == .loading || state == .idle {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isEmpty, let error = state.error {
            ContentUnavailableView {
                Label("Couldn't load", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Try again") { Task { await model.refresh() } }
            }
        } else if isEmpty, let empty {
            empty
        } else {
            content
        }
    }
}
