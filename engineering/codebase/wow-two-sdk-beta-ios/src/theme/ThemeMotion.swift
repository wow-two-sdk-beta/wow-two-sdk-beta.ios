import SwiftUI

/// A cubic-bézier easing — the fe sdk's `--ease-*` control points.
public struct EasingToken: Sendable, Hashable {
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double

    public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }

    /// Enter — decelerate.
    public static let out = EasingToken(0, 0, 0.2, 1)
    /// Exit — accelerate.
    public static let `in` = EasingToken(0.4, 0, 1, 1)
    /// Moves within the screen.
    public static let standard = EasingToken(0.4, 0, 0.2, 1)
}

/// Durations and easings — the fe sdk's `--duration-{fast,base,slow}` and `--ease-{out,in,standard}`.
public struct ThemeMotion: Sendable, Hashable {
    public enum Speed: Sendable, CaseIterable { case fast, base, slow }

    public var fast: Double
    public var base: Double
    public var slow: Double
    /// One sweep of the skeleton shimmer — the fe sdk's `--animate-shimmer`.
    public var shimmer: Double
    /// One sweep of an indeterminate progress bar — the fe sdk's `ProgressBar` indeterminate slide.
    public var indeterminate: Double

    public init(
        fast: Double = 0.15,
        base: Double = 0.2,
        slow: Double = 0.3,
        shimmer: Double = 1.6,
        indeterminate: Double = 1.4
    ) {
        self.fast = fast
        self.base = base
        self.slow = slow
        self.shimmer = shimmer
        self.indeterminate = indeterminate
    }

    /// Seconds for `speed`.
    public func duration(_ speed: Speed) -> Double {
        switch speed {
        case .fast: fast
        case .base: base
        case .slow: slow
        }
    }

    /// The animation for `speed` and `easing`; `nil` under Reduce Motion, so `withAnimation(nil)` jumps.
    public func animation(
        _ speed: Speed = .base,
        _ easing: EasingToken = .standard,
        reduceMotion: Bool = false
    ) -> Animation? {
        if reduceMotion { return nil }
        return .timingCurve(easing.x1, easing.y1, easing.x2, easing.y2, duration: duration(speed))
    }

    public static let standard = ThemeMotion()
}
