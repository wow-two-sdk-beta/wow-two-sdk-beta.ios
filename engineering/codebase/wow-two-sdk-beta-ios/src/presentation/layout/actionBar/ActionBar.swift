import SwiftUI
import WoW2IosTheme

/// A bottom bar of actions — usually one or two full-width buttons — on a themed surface with a top hairline, its
/// fill carried under the home indicator. The fe sdk's `StickyLayout` with `side: 'bottom'`.
///
/// Pin it with `.actionBar { … }`, which places it through `safeAreaInset(edge: .bottom)` so scroll content runs
/// under it and stops above it; place the view yourself only where no safe-area inset fits.
public struct ActionBar<Content: View>: View {
    private let variant: ActionBarVariant
    private let axis: Axis
    private let content: Content

    @Environment(\.wow2Theme) private var theme

    /// - Parameter axis: `.vertical` stacks the controls (full-width buttons); `.horizontal` sets them side by side.
    public init(
        variant: ActionBarVariant = .page,
        axis: Axis = .vertical,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.axis = axis
        self.content = content()
    }

    public var body: some View {
        let look = ActionBarAppearance.resolve(theme: theme, variant: variant)
        let layout = axis == .vertical
            ? AnyLayout(VStackLayout(spacing: look.spacing))
            : AnyLayout(HStackLayout(spacing: look.spacing))

        layout { content }
            .padding(.horizontal, look.horizontalPadding)
            .padding(.vertical, look.verticalPadding)
            .frame(maxWidth: .infinity)
            .background {
                look.background.color
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(look.border.color)
                    .frame(height: look.borderWidth)
                    .accessibilityHidden(true)
            }
    }
}

extension View {
    /// Pins an `ActionBar` holding `content` to the bottom edge, above the home indicator; the view's scroll
    /// content runs under the bar and its last row stops above it.
    public func actionBar<Content: View>(
        variant: ActionBarVariant = .page,
        axis: Axis = .vertical,
        @ViewBuilder content: () -> Content
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            ActionBar(variant: variant, axis: axis, content: content)
        }
    }
}
