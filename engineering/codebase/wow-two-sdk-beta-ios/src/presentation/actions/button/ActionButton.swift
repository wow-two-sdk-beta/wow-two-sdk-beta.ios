import SwiftUI
import WoW2IosTheme

/// A themed button that runs an async action, shows itself busy until the action returns and ignores taps
/// meanwhile — the fe sdk's `Button` with `isLoading`, without the caller keeping a flag.
public struct ActionButton<Label: View>: View {
    private let variant: ButtonVariant
    private let size: ButtonSize
    private let isFullWidth: Bool
    private let isBusy: Bool
    private let action: @MainActor () async -> Void
    private let label: Label

    @State private var isRunning = false

    /// - Parameter isBusy: Busy from outside, beside the button's own run.
    public init(
        variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isBusy: Bool = false,
        action: @escaping @MainActor () async -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
        self.isBusy = isBusy
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(role: variant == .destructive ? .destructive : nil) {
            run()
        } label: {
            label
        }
        .buttonStyle(.theme(variant, size: size, isBusy: isBusy || isRunning, isFullWidth: isFullWidth))
    }

    private func run() {
        guard !isRunning, !isBusy else { return }
        isRunning = true
        Task {
            await action()
            isRunning = false
        }
    }
}

extension ActionButton where Label == ButtonLabel {
    /// A button titled `title`, with an SF Symbol before it when `systemImage` is set.
    public init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isBusy: Bool = false,
        action: @escaping @MainActor () async -> Void
    ) {
        self.init(variant: variant, size: size, isFullWidth: isFullWidth, isBusy: isBusy, action: action) {
            ButtonLabel(title, systemImage: systemImage)
        }
    }

    /// Renders `title` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        _ title: Title,
        systemImage: String? = nil,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isBusy: Bool = false,
        action: @escaping @MainActor () async -> Void
    ) {
        self.init(variant: variant, size: size, isFullWidth: isFullWidth, isBusy: isBusy, action: action) {
            ButtonLabel(title, systemImage: systemImage)
        }
    }
}

/// A button's title with an optional leading SF Symbol.
public struct ButtonLabel: View {
    private let title: Text
    private let systemImage: String?

    @Environment(\.wow2Theme) private var theme

    public init(_ title: LocalizedStringKey, systemImage: String? = nil) {
        self.title = Text(title)
        self.systemImage = systemImage
    }

    /// Renders `title` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(_ title: Title, systemImage: String? = nil) {
        self.title = Text(title)
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage).accessibilityHidden(true)
            }
            title
        }
    }
}
