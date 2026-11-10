import SwiftUI
import WoW2Ios

/// Spinner, LoadingState, IconButton, ToggleIconButton and MediaPill in their states; the over-media forms on a
/// dark sample surface standing in for a camera picture.
public struct FeedbackActionsShowcase: View {
    @State private var isFavorite = true
    @State private var isMuted = false
    @State private var isGridOn = false

    @Environment(\.wow2Theme) private var theme

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
            SectionHeader("Spinners", subtitle: "Spinner · LoadingState")
            HStack(spacing: theme.spacing.lg) {
                ForEach(SpinnerSize.allCases, id: \.self) { size in
                    Spinner(tone: .primary, size: size)
                }
                Spinner("Loading", tone: .neutral)
            }
            LoadingState("Loading purchases…", message: "This takes a moment.")
                .frame(height: theme.sizes.avatarExtraLarge * 2)

            SectionHeader("Icon buttons", subtitle: "IconButton · ToggleIconButton · .icon(_:)")
            ForEach(IconButtonSize.allCases, id: \.self) { size in
                HStack(spacing: theme.spacing.sm) {
                    IconButton(systemImage: "gearshape", label: "Settings", variant: .ghost, size: size) {}
                    IconButton(systemImage: "square.and.arrow.up", label: "Share", variant: .soft, size: size) {}
                    IconButton(systemImage: "plus", label: "Add", variant: .filled, size: size) {}
                    IconButton(systemImage: "trash", label: "Delete", variant: .soft, size: size, role: .destructive) {}
                    IconButton(systemImage: "pencil", label: "Edit", variant: .filled, size: size) {}
                        .disabled(true)
                }
            }
            HStack(spacing: theme.spacing.sm) {
                ToggleIconButton(isOn: $isFavorite, systemImage: "star", selectedSystemImage: "star.fill",
                                 label: "Favorite", selectedTone: .warning)
                ToggleIconButton(isOn: $isMuted, systemImage: "speaker.wave.2", selectedSystemImage: "speaker.slash",
                                 label: "Mute", variant: .soft)
                ToggleIconButton(isOn: $isGridOn, systemImage: "grid", label: "Grid", variant: .filled)
            }

            SectionHeader("Over media", subtitle: "MediaPill · overMedia")
            mediaSample
        }
    }

    private var mediaSample: some View {
        VStack(spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.sm) {
                Button("Close", systemImage: "xmark") {}.buttonStyle(.icon(.overMedia))
                Spacer()
                IconButton(systemImage: "arrow.trianglehead.2.clockwise.rotate.90", label: "Turn around",
                           variant: .overMedia) {}
                ToggleIconButton(isOn: $isFavorite, systemImage: "star", selectedSystemImage: "star.fill",
                                 label: "Favorite", variant: .overMedia, selectedTone: .warning)
            }
            MediaPill("Hold the phone steady", systemImage: "hand.raised", size: .small)
            ForEach([Array(MediaPillTone.allCases.prefix(3)), Array(MediaPillTone.allCases.dropFirst(3))], id: \.self) { row in
                HStack(spacing: theme.spacing.sm) {
                    ForEach(row, id: \.self) { tone in
                        MediaPill(tone.rawValue.capitalized, tone: tone, size: .small)
                    }
                }
            }
            MediaPill("Show this to the person you're photographing")
            Spinner("Preparing photo…", tone: .overMedia)
            LoadingState("Matching the photos…", tone: .overMedia)
                .frame(height: theme.sizes.avatarExtraLarge * 2)
        }
        .padding(theme.spacing.lg)
        .background {
            // A stand-in picture: the theme's dark-mode fills, dark and busy like a camera frame in either mode.
            LinearGradient(
                colors: [theme.colors.background.color, theme.colors.primary.soft.color, theme.colors.accent.base.color],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
            .environment(\.colorScheme, .dark)
        }
    }
}

#Preview("Feedback & actions") {
    ScrollView {
        FeedbackActionsShowcase().padding()
    }
    .themedBackground()
    .wow2Theme(.standard)
}
