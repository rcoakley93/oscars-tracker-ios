import SwiftUI

// The tabs here are the shell's placeholder screens (P3-05, P3-10). They use
// the real stores in plain system lists styled with the tokens, laid out in
// the containers the finished screens use. Phase 4 replaces each one.

/// Shows a store's loading and error states around its content. While it
/// loads with nothing to show, the real layout stands in, redacted and hidden
/// from VoiceOver (screens.md, section 2), or a spinner when a screen has no
/// placeholder yet.
struct LoadStateView<Content: View, Placeholder: View>: View {
    let state: LoadState
    let isEmpty: Bool
    var empty: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView>? = nil
    @ViewBuilder var content: Content
    @ViewBuilder var placeholder: Placeholder
    @Environment(AppModel.self) private var model

    init(state: LoadState, isEmpty: Bool, empty: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView>? = nil,
         @ViewBuilder content: () -> Content, @ViewBuilder placeholder: () -> Placeholder) {
        self.state = state
        self.isEmpty = isEmpty
        self.empty = empty
        self.content = content()
        self.placeholder = placeholder()
    }

    var body: some View {
        if isEmpty, state == .loading || state == .idle {
            placeholder
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
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

extension LoadStateView where Placeholder == AnyView {
    init(state: LoadState, isEmpty: Bool, empty: ContentUnavailableView<Label<Text, Image>, Text?, EmptyView>? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(state: state, isEmpty: isEmpty, empty: empty, content: content) {
            AnyView(ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity))
        }
    }
}
