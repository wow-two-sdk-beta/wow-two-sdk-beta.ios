import SwiftUI
import WoW2IosTheme

/// A themed indeterminate progress indicator with an optional label under it — the fe sdk's `Spinner`. It
/// styles the native `ProgressView`, so VoiceOver reads "In progress" (or the label) and announces it as busy.
public struct Spinner: View {
    private let label: Text?
    private let tone: SpinnerTone
    private let size: SpinnerSize

    @Environment(\.wow2Theme) private var theme

    /// A bare indicator; VoiceOver reads the system's "In progress".
    public init(tone: SpinnerTone = .neutral, size: SpinnerSize = .medium) {
        self.label = nil
        self.tone = tone
        self.size = size
    }

    /// An indicator with `label` under it — `Spinner("Preparing photo…", tone: .overMedia)`.
    public init(_ label: LocalizedStringKey, tone: SpinnerTone = .neutral, size: SpinnerSize = .medium) {
        self.label = Text(label)
        self.tone = tone
        self.size = size
    }

    /// Renders `label` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Label: StringProtocol>(_ label: Label, tone: SpinnerTone = .neutral, size: SpinnerSize = .medium) {
        self.label = Text(label)
        self.tone = tone
        self.size = size
    }

    public var body: some View {
        let look = SpinnerAppearance.resolve(theme: theme, tone: tone, size: size)

        VStack(spacing: look.spacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(look.size.controlSize)
                .tint(look.tint.color)
            if let label {
                label
                    .font(look.labelFont.font)
                    .foregroundStyle(look.labelForeground.color)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(look.padding)
        .background {
            if let background = look.background {
                RoundedRectangle(cornerRadius: look.radius, style: .continuous).fill(background.color)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension SpinnerSize {
    var controlSize: ControlSize {
        switch self {
        case .small: .small
        case .medium: .regular
        case .large: .large
        }
    }
}
