import SwiftUI

/// How a control shows that it is disabled or pressed — the fe sdk's `disabled:opacity-*` and `active:` utilities.
/// One set of values, so every control dims and yields the same way.
public struct ThemeStates: Sendable, Hashable {
    /// The opacity of a disabled control.
    public var disabledOpacity: Double
    /// The opacity of a filled control, a card or a row while it is pressed.
    public var pressedOpacity: Double
    /// The scale of a tile while it is pressed; Reduce Motion keeps it at 1.
    public var pressedScale: CGFloat
    /// The opacity of the tone washed over pressed art — the fe sdk's `bg-primary/10`.
    public var pressedWashOpacity: Double

    public init(
        disabledOpacity: Double = 0.45,
        pressedOpacity: Double = 0.85,
        pressedScale: CGFloat = 0.97,
        pressedWashOpacity: Double = 0.1
    ) {
        self.disabledOpacity = disabledOpacity
        self.pressedOpacity = pressedOpacity
        self.pressedScale = pressedScale
        self.pressedWashOpacity = pressedWashOpacity
    }

    public static let standard = ThemeStates()
}
