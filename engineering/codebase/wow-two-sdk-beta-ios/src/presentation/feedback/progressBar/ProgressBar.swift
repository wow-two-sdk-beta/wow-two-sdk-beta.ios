import SwiftUI
import WoW2IosTheme

/// The fill's colour — the fe sdk's `ProgressTone`, `brand` named `primary` as the theme names it.
public enum ProgressBarTone: String, Sendable, CaseIterable {
    case primary, success, warning, danger, neutral
}

/// The track thickness step.
public enum ProgressBarSize: String, Sendable, CaseIterable {
    case small, medium, large
}

/// Everything a progress bar draws, resolved from the theme alone — the fe sdk's `ProgressBar.variants.ts`.
public struct ProgressBarAppearance: Sendable, Hashable {
    public var track: ColorToken
    public var fill: ColorToken
    public var height: CGFloat
    /// The share of the track the indeterminate segment covers.
    public var indeterminateWidth: Double
    /// One sweep of the indeterminate segment, in seconds.
    public var indeterminateDuration: Double

    public static func resolve(
        theme: Theme,
        tone: ProgressBarTone = .primary,
        size: ProgressBarSize = .medium
    ) -> ProgressBarAppearance {
        let colors = theme.colors
        let fill: ColorToken = switch tone {
        case .primary: colors.primary.base
        case .success: colors.success.base
        case .warning: colors.warning.base
        case .danger: colors.destructive.base
        case .neutral: colors.mutedForeground
        }
        let height: CGFloat = switch size {
        case .small: theme.spacing.xs
        case .medium: theme.spacing.sm
        case .large: theme.spacing.md
        }
        return ProgressBarAppearance(
            track: colors.muted,
            fill: fill,
            height: height,
            indeterminateWidth: 0.35,
            indeterminateDuration: theme.motion.indeterminate
        )
    }
}

/// A horizontal progress bar: determinate for a known share of work (`0...1`), indeterminate (`value: nil`) for
/// work of unknown length — the fe sdk's `ProgressBar`. VoiceOver reads the percentage; the indeterminate segment
/// stops sliding under Reduce Motion and the determinate fill jumps.
public struct ProgressBar: View {
    private let value: Double?
    private let tone: ProgressBarTone
    private let size: ProgressBarSize
    private let label: Text?

    @Environment(\.wow2Theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - value: The share done, clamped to `0...1`; `nil` is indeterminate.
    ///   - label: What VoiceOver names the bar, e.g. "Uploading".
    public init(
        value: Double?,
        tone: ProgressBarTone = .primary,
        size: ProgressBarSize = .medium,
        label: LocalizedStringKey? = nil
    ) {
        self.value = value.map { min(max($0, 0), 1) }
        self.tone = tone
        self.size = size
        self.label = label.map { Text($0) }
    }

    /// Names the bar with `label` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Label: StringProtocol>(
        value: Double?,
        tone: ProgressBarTone = .primary,
        size: ProgressBarSize = .medium,
        label: Label
    ) {
        self.value = value.map { min(max($0, 0), 1) }
        self.tone = tone
        self.size = size
        self.label = Text(label)
    }

    public var body: some View {
        let look = ProgressBarAppearance.resolve(theme: theme, tone: tone, size: size)

        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(look.track.color)
                if let value {
                    Capsule()
                        .fill(look.fill.color)
                        .frame(width: proxy.size.width * value)
                        .animation(theme.motion.animation(.slow, reduceMotion: reduceMotion), value: value)
                } else {
                    IndeterminateSegment(look: look, width: proxy.size.width, reduceMotion: reduceMotion)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: look.height)
        .accessibilityElement()
        .accessibilityLabel(label ?? Text("Progress"))
        .accessibilityValue(value.map { Text($0, format: .percent.precision(.fractionLength(0))) } ?? Text("In progress"))
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// The sliding segment of an indeterminate bar, its position read from the clock; a still, faint full-width fill
/// under Reduce Motion.
private struct IndeterminateSegment: View {
    let look: ProgressBarAppearance
    let width: CGFloat
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            Capsule().fill(look.fill.opacity(0.4).color)
        } else {
            TimelineView(.animation) { context in
                let duration = max(look.indeterminateDuration, 0.1)
                let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
                let segment = width * look.indeterminateWidth
                Capsule()
                    .fill(look.fill.color)
                    .frame(width: segment)
                    .offset(x: -segment + CGFloat(phase) * (width + segment))
            }
        }
    }
}
