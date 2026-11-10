import SwiftUI
import WoW2Ios

/// `MediaCard`, `BulletList`, `ActionBar` and `TopBar` in their states, without scroll or navigation chrome.
public struct DisplayLayoutShowcase: View {
    @State private var isFavorite = true

    @Environment(\.wow2Theme) private var theme

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
            SectionHeader("Media cards", subtitle: "MediaCard · tappable, static, accessory")
            HStack(alignment: .top, spacing: theme.spacing.lg) {
                MediaCard("Golden hour", caption: "Soft side light, face the sun at 45°.", action: {}) {
                    placeholder("sun.max", tone: theme.colors.warning)
                } accessory: {
                    favoriteStar
                }
                MediaCard(String("Static"), caption: String("No action: a plain tile, rendered verbatim.")) {
                    placeholder("photo", tone: theme.colors.primary)
                }
            }
            HStack(alignment: .top, spacing: theme.spacing.lg) {
                MediaCard("Wide", caption: "16 : 9 media.", aspectRatio: 16 / 9, action: {}) {
                    placeholder("film", tone: theme.colors.info)
                }
                MediaCard("Disabled", caption: "Dims the whole card.", aspectRatio: 16 / 9, action: {}) {
                    placeholder("lock", tone: theme.colors.destructive)
                }
                .disabled(true)
            }

            SectionHeader("Bullet lists", subtitle: "BulletList · dot, symbol, number × tone")
            BulletList(["Shoulders square to the camera", "Chin slightly down, eyes up to the lens, a longer line that wraps"])
            BulletList(["Any background", "Any outfit"], marker: .symbol("checkmark"), tone: .success)
            BulletList([String("No flash"), String("No zoom")], marker: .symbol("xmark"), tone: .danger)
            BulletList(
                ["Pick a pattern", "Frame the shot", "Hold still", "Review", "Share", "Pick a pattern", "Frame",
                 "Hold", "Review", "Share the tenth shot"],
                marker: .number,
                tone: .neutral
            )

            SectionHeader("Action bar", subtitle: "ActionBar · vertical, horizontal, card")
            ActionBar {
                Button("Take photos", systemImage: "camera") {}
                    .buttonStyle(.theme(.primary, isFullWidth: true))
                Button("Shoot with two phones", systemImage: "iphone.gen3.radiowaves.left.and.right") {}
                    .buttonStyle(.theme(.secondary, isFullWidth: true))
            }
            ActionBar(variant: .card, axis: .horizontal) {
                Button("Cancel") {}.buttonStyle(.theme(.secondary, isFullWidth: true))
                Button("Save") {}.buttonStyle(.theme(.primary, isFullWidth: true))
            }

            SectionHeader("Top bar", subtitle: "TopBar · both slots, subtitle, one slot, uneven slots")
            TopBar("Person 1 of 2", isInset: false) {
                IconButton(systemImage: "xmark", label: "Close") {}
            } trailing: {
                IconButton(systemImage: "arrow.triangle.2.circlepath.camera", label: "Switch camera") {}
                    .disabled(true)
            }
            TopBar("Golden hour", subtitle: "Duo collage", isInset: false) {
                IconButton(systemImage: "xmark", label: "Close") {}
            } trailing: {
                Menu("Retake") {
                    Button("Person 1") {}
                    Button("Person 2") {}
                }
            }
            TopBar(String("Settings"), isInset: false, trailing: {
                IconButton(systemImage: "checkmark", label: "Done", variant: .filled) {}
            })
            TopBar("A long title that truncates before it reaches a slot", isInset: false) {
                IconButton(systemImage: "chevron.left", label: "Back") {}
            } trailing: {
                IconButton(systemImage: "square.and.arrow.up", label: "Share") {}
                IconButton(systemImage: "ellipsis", label: "More") {}
            }
        }
    }

    /// A media stand-in drawn from tokens: a soft-to-base gradient in the tone under an SF Symbol.
    private func placeholder(_ systemImage: String, tone: ToneColors) -> some View {
        LinearGradient(
            colors: [tone.soft.color, tone.base.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: systemImage)
                .font(theme.typography.display.font)
                .foregroundStyle(tone.foreground.color)
        }
    }

    private var favoriteStar: some View {
        Button {
            isFavorite.toggle()
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(theme.typography.heading.font)
                .foregroundStyle((isFavorite ? theme.colors.warning.base : theme.colors.foreground).color)
                .frame(width: theme.sizes.controlMedium, height: theme.sizes.controlMedium)
                .background(theme.colors.card.color, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Mark as favorite")
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
    }
}

#Preview("Light") {
    ScrollView {
        DisplayLayoutShowcase().padding()
    }
    .themedBackground()
}

#Preview("Dark") {
    ScrollView {
        DisplayLayoutShowcase().padding()
    }
    .themedBackground()
    .preferredColorScheme(.dark)
}
