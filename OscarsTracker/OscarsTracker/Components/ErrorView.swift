import SwiftUI

/// A standardized error view for failed data loads.
struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    let icon: String

    init(
        title: String = "Something went wrong",
        message: String = "We couldn't load the data. Please try again.",
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.destructive)

            Text(title)
                .font(.headingMedium)
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(.bodyMedium)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                }
                .buttonStyle(.gold)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(title). \(message)")
        .accessibilityHint(retryAction != nil ? "Double tap to retry" : "")
    }
}

/// A network-specific error view.
struct NetworkErrorView: View {
    let retryAction: () -> Void

    var body: some View {
        ErrorView(
            title: "No Connection",
            message: "Please check your internet connection and try again.",
            icon: "wifi.slash",
            retryAction: retryAction
        )
    }
}

/// A toast notification for transient messages.
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: (() -> Void)?

    enum ToastType {
        case error
        case success
        case warning
        case info

        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .error: return .destructive
            case .success: return .success
            case .warning: return .goldPrimary
            case .info: return .textPrimary
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundStyle(type.color)

            Text(message)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if onDismiss != nil {
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                }
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type == .error ? "Error" : type == .success ? "Success" : type == .warning ? "Warning" : "Info"): \(message)")
    }
}

/// A view modifier that adds toast notification capability.
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    let position: ToastPosition

    enum ToastPosition {
        case top
        case bottom
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if position == .bottom { Spacer() }

                if let toast = toast {
                    ToastView(
                        message: toast.message,
                        type: toast.type,
                        onDismiss: { self.toast = nil }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, position == .top ? 50 : 100)
                    .transition(.move(edge: position == .top ? .top : .bottom).combined(with: .opacity))
                    .onAppear {
                        if toast.autoDismiss {
                            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    self.toast = nil
                                }
                            }
                        }
                    }
                }

                if position == .top { Spacer() }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toast != nil)
        }
    }
}

/// Data model for toast notifications.
struct ToastData: Equatable {
    let id: UUID
    let message: String
    let type: ToastView.ToastType
    let autoDismiss: Bool
    let duration: TimeInterval

    init(
        message: String,
        type: ToastView.ToastType = .info,
        autoDismiss: Bool = true,
        duration: TimeInterval = 3.0
    ) {
        self.id = UUID()
        self.message = message
        self.type = type
        self.autoDismiss = autoDismiss
        self.duration = duration
    }

    static func error(_ message: String) -> ToastData {
        ToastData(message: message, type: .error)
    }

    static func success(_ message: String) -> ToastData {
        ToastData(message: message, type: .success)
    }

    static func warning(_ message: String) -> ToastData {
        ToastData(message: message, type: .warning)
    }

    static func info(_ message: String) -> ToastData {
        ToastData(message: message, type: .info)
    }

    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        lhs.id == rhs.id
    }
}

/// Extension to easily add toast capability to any view.
extension View {
    func toast(_ toast: Binding<ToastData?>, position: ToastModifier.ToastPosition = .bottom) -> some View {
        modifier(ToastModifier(toast: toast, position: position))
    }
}

/// An inline error banner for form validation errors.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.destructive)

            Text(message)
                .font(.bodySmall)
                .foregroundStyle(Color.destructive)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.destructive.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

/// A graceful degradation view for partial failures.
struct PartialErrorView: View {
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.goldPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text(message)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("ErrorView") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ErrorView(
            title: "Failed to Load",
            message: "We couldn't load your movies. Please try again.",
            retryAction: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("NetworkErrorView") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        NetworkErrorView(retryAction: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("ToastView") {
    VStack(spacing: 16) {
        ToastView(message: "An error occurred", type: .error, onDismiss: {})
        ToastView(message: "Successfully saved", type: .success, onDismiss: {})
        ToastView(message: "Connection unstable", type: .warning, onDismiss: {})
        ToastView(message: "Update available", type: .info, onDismiss: {})
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("ErrorBanner") {
    VStack {
        ErrorBanner(message: "Invalid username. Please try again.")
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("PartialErrorView") {
    VStack {
        PartialErrorView(
            title: "Some data unavailable",
            message: "We couldn't load all categories. Pull to refresh."
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
