import SwiftUI
import WoW2IosTheme

/// A toast's severity; every tone but `neutral` shows its glyph so severity never rests on colour alone.
public enum ToastTone: String, Sendable, CaseIterable {
    case neutral, info, success, warning, destructive

    /// The theme tone family, `nil` for neutral.
    public var tone: Tone? {
        switch self {
        case .neutral: nil
        case .info: .info
        case .success: .success
        case .warning: .warning
        case .destructive: .destructive
        }
    }

    public var systemImage: String? {
        switch self {
        case .neutral: nil
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .destructive: "xmark.octagon.fill"
        }
    }
}

/// One toast to show.
public struct ToastMessage: Identifiable, Sendable, Hashable {
    public var id: UUID
    public var title: String
    public var message: String?
    public var tone: ToastTone
    /// How long it stays before it dismisses itself.
    public var duration: Duration

    public init(
        _ title: String,
        message: String? = nil,
        tone: ToastTone = .neutral,
        duration: Duration = .seconds(3),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
        self.duration = duration
    }
}

/// The toast queue an app owns: one toast on screen, the rest waiting in order — the fe sdk's feedback bus
/// feeding `ToastHost`. Read it anywhere below `.toastHost(_:)` with `@Environment(ToastCenter.self)`.
@MainActor
@Observable
public final class ToastCenter {
    /// The toast on screen.
    public private(set) var current: ToastMessage?
    /// The toasts waiting behind it.
    public private(set) var pending: [ToastMessage] = []

    public init() {}

    /// Queues `toast`; it shows at once when nothing else is on screen.
    public func show(_ toast: ToastMessage) {
        if current == nil {
            current = toast
        } else {
            pending.append(toast)
        }
    }

    /// Queues a toast built from its parts and returns its id.
    @discardableResult
    public func show(
        _ title: String,
        message: String? = nil,
        tone: ToastTone = .neutral,
        duration: Duration = .seconds(3)
    ) -> ToastMessage.ID {
        let toast = ToastMessage(title, message: message, tone: tone, duration: duration)
        show(toast)
        return toast.id
    }

    /// Removes the toast `id` names — the current one by default — and brings the next forward.
    public func dismiss(_ id: ToastMessage.ID? = nil) {
        if id == nil || id == current?.id {
            current = pending.isEmpty ? nil : pending.removeFirst()
        } else {
            pending.removeAll { $0.id == id }
        }
    }

    /// Removes every toast.
    public func clear() {
        pending.removeAll()
        current = nil
    }
}

/// The toast surface: the severity glyph, a title and an optional line — the fe sdk's `Toast`.
public struct Toast: View {
    private let toast: ToastMessage
    private let onDismiss: (@MainActor () -> Void)?

    @Environment(\.wow2Theme) private var theme

    public init(_ toast: ToastMessage, onDismiss: (@MainActor () -> Void)? = nil) {
        self.toast = toast
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)

        HStack(alignment: .top, spacing: theme.spacing.sm) {
            if let systemImage = toast.tone.systemImage, let tone = toast.tone.tone {
                Image(systemName: systemImage)
                    .font(theme.typography.label.font)
                    .foregroundStyle(theme.colors[tone].softForeground.color)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(toast.title)
                    .font(theme.typography.label.font)
                    .foregroundStyle(theme.colors.popoverForeground.color)
                if let message = toast.message {
                    Text(message)
                        .font(theme.typography.caption.font)
                        .foregroundStyle(theme.colors.mutedForeground.color)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: 560)
        .background { shape.fill(theme.colors.popover.color) }
        .overlay { shape.strokeBorder(theme.colors.border.color, lineWidth: theme.sizes.hairline) }
        .shadow(theme.elevation.overlay)
        .contentShape(shape)
        .onTapGesture { onDismiss?() }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: Text("Dismiss")) { onDismiss?() }
    }
}

extension View {
    /// Shows `center`'s toasts over this view at `edge`, each for its duration, announced to VoiceOver; puts
    /// `center` in the environment for `@Environment(ToastCenter.self)`.
    public func toastHost(_ center: ToastCenter, edge: VerticalEdge = .top) -> some View {
        modifier(ToastHost(center: center, edge: edge))
    }
}

private struct ToastHost: ViewModifier {
    let center: ToastCenter
    let edge: VerticalEdge

    @Environment(\.wow2Theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: edge == .top ? .top : .bottom) {
                ZStack {
                    if let toast = center.current {
                        Toast(toast) { center.dismiss(toast.id) }
                            .padding(.horizontal, theme.spacing.lg)
                            .padding(.vertical, theme.spacing.sm)
                            .transition(transition)
                            .id(toast.id)
                    }
                }
                .animation(theme.motion.animation(.base, .out, reduceMotion: reduceMotion), value: center.current)
                .task(id: center.current?.id) {
                    guard let toast = center.current else { return }
                    AccessibilityNotification.Announcement(toast.title).post()
                    try? await Task.sleep(for: toast.duration)
                    if !Task.isCancelled { center.dismiss(toast.id) }
                }
            }
            .environment(center)
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge == .top ? .top : .bottom).combined(with: .opacity)
    }
}
