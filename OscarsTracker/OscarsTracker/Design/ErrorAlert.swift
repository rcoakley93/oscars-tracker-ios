import SwiftUI

extension View {
    /// The one way a store's `actionError` reaches people (P4-11): an alert
    /// with a plain title and `AppError`'s friendly text, never a raw server
    /// message. A cancelled Apple or Google sheet shows nothing.
    func errorAlert(_ title: String, error: Binding<AppError?>) -> some View {
        alert(title, isPresented: Binding {
            error.wrappedValue.map { $0 != .cancelled } ?? false
        } set: {
            if !$0 { error.wrappedValue = nil }
        }, presenting: error.wrappedValue) { _ in
            Button("OK") {}
        } message: { error in
            Text(error.message)
        }
    }
}
