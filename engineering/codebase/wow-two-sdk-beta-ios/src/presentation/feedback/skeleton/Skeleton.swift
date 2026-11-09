import SwiftUI
import WoW2IosTheme

/// A placeholder block for content still loading: the muted fill with a shimmer sweep, static under Reduce
/// Motion — the fe sdk's `Skeleton`.
public struct Skeleton: View {
    private let width: CGFloat?
    private let height: CGFloat
    private let radius: CGFloat?

    @Environment(\.wow2Theme) private var theme

    /// - Parameter width: `nil` fills the container's width.
    public init(width: CGFloat? = nil, height: CGFloat = 16, radius: CGFloat? = nil) {
        self.width = width
        self.height = height
        self.radius = radius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: radius ?? theme.radii.sm, style: .continuous)
            .fill(theme.colors.muted.color)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .shimmer(true)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Shows this view as its own skeleton while `isActive`: text and images redacted to placeholder blocks, a
    /// shimmer over them, taps ignored, and VoiceOver reading "Loading" — the fe sdk's `isSkeleton`.
    public func skeleton(_ isActive: Bool) -> some View {
        modifier(SkeletonModifier(isActive: isActive))
    }

    /// Sweeps a light band across this view's shape while `isActive`; static under Reduce Motion.
    public func shimmer(_ isActive: Bool = true) -> some View {
        modifier(Shimmer(isActive: isActive))
    }
}

private struct SkeletonModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content
                .redacted(reason: .placeholder)
                .shimmer(true)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Loading"))
        } else {
            content
        }
    }
}

private struct Shimmer: ViewModifier {
    let isActive: Bool

    @Environment(\.wow2Theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, theme.colors.card.opacity(0.55).color, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.4)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.linear(duration: theme.motion.shimmer).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            }
    }
}
