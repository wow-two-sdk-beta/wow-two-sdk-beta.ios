import SwiftUI
import WoW2Ios

/// The selection components in their states: `OptionTile`, `OptionTileStrip` and `ChoiceField`.
public struct SelectionShowcase: View {
    @State private var style = "violet"
    @State private var stripStyle = "teal"
    @State private var voice = "calm"
    @State private var language = "system"

    @Environment(\.wow2Theme) private var theme

    public init() {}

    private struct Swatch: Identifiable {
        let id: String
        let title: String
        let tone: Tone
        let systemImage: String
    }

    private let swatches: [Swatch] = [
        Swatch(id: "violet", title: "Violet", tone: .primary, systemImage: "eye"),
        Swatch(id: "teal", title: "Teal", tone: .info, systemImage: "eyes"),
        Swatch(id: "amber", title: "Amber", tone: .warning, systemImage: "sun.max"),
        Swatch(id: "mint", title: "Mint", tone: .success, systemImage: "leaf"),
        Swatch(id: "rose", title: "Rose", tone: .destructive, systemImage: "heart"),
        Swatch(id: "sky", title: "Sky", tone: .accent, systemImage: "cloud"),
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
            SectionHeader("Option tiles", subtitle: "OptionTile · unselected, selected, title above, hidden, disabled")
            HStack(alignment: .top, spacing: theme.spacing.md) {
                OptionTile("Calm", isSelected: false, action: {}) { art(.info, "wind") }
                OptionTile("Bright", isSelected: true, action: {}) { art(.primary, "sparkles") }
                OptionTile("Above", isSelected: false, titlePosition: .above, action: {}) { art(.success, "leaf") }
            }
            HStack(alignment: .top, spacing: theme.spacing.md) {
                OptionTile(String("Hidden title"), isSelected: true, titlePosition: .hidden, action: {}) {
                    art(.warning, "sun.max")
                }
                OptionTile("Disabled", isSelected: false, action: {}) { art(.accent, "cloud") }
                    .disabled(true)
            }

            SectionHeader("Option tile strip", subtitle: "OptionTileStrip · one selection, scrolls it into view")
            OptionTileStrip(swatches, selection: $style, value: \.id, title: { $0.title }) { swatch in
                art(swatch.tone, swatch.systemImage)
            }
            OptionTileStrip(
                swatches, selection: $stripStyle, value: \.id, title: { $0.title }, titlePosition: .hidden
            ) {
                Image(systemName: "photo.badge.plus")
                    .font(theme.typography.title.font)
                    .foregroundStyle(theme.colors.mutedForeground.color)
                    .frame(width: theme.spacing(20), height: theme.spacing(14))
                    .background(
                        RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                            .fill(theme.colors.muted.color)
                    )
                    .accessibilityLabel(Text(verbatim: "Your picture"))
            } art: { swatch in
                art(swatch.tone, swatch.systemImage, width: theme.spacing(20), height: theme.spacing(14))
            }

            SectionHeader("Choice fields", subtitle: "ChoiceField · the radio of a list")
            ListGroup("Voice", separator: .inset) {
                ChoiceField("Calm", subtitle: "Slow, low", systemImage: "wind", value: "calm", selection: $voice)
                ChoiceField("Energetic", subtitle: "Fast, bright", systemImage: "bolt", value: "energetic", selection: $voice)
                ChoiceField("Muted", systemImage: "speaker.slash", value: "muted", selection: $voice)
                    .disabled(true)
            }
            ListGroup(String("App language"), footer: String("Strings render verbatim.")) {
                ChoiceField(String("System default"), isSelected: language == "system") { language = "system" }
                ChoiceField(String("English"), value: "en", selection: $language)
                ChoiceField(String("Deutsch"), subtitle: String("German"), value: "de", selection: $language)
            }
        }
    }

    private func art(_ tone: Tone, _ systemImage: String, width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        Image(systemName: systemImage)
            .font(theme.typography.title.font)
            .foregroundStyle(theme.colors[tone].softForeground.color)
            .frame(width: width ?? theme.spacing(18), height: height ?? theme.spacing(18))
            .background(theme.colors[tone].soft.color)
    }
}

#Preview("Selection") {
    ScrollView {
        SelectionShowcase().padding()
    }
    .wow2Theme(.standard)
}
