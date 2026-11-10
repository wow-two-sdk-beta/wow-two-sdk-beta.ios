import SwiftUI
import WoW2Ios

/// A second theme that changes a handful of tokens, to show one theme restyling every component.
public extension Theme {
    static let showcaseBrand = Theme.standard.with(id: "brand") { theme in
        theme.colors.primary = ToneColors(
            base: ColorToken("#7c3aed", "#a78bfa"),
            foreground: ColorToken("#ffffff", "#1e1b4b"),
            soft: ColorToken("#ede9fe", "#3b0764"),
            softForeground: ColorToken("#5b21b6", "#ede9fe")
        )
        theme.colors.ring = ColorToken("#7c3aed", "#a78bfa")
        theme.radii = theme.radii.scaled(1.6)
        theme.typography = theme.typography.design(.rounded)
    }
}

/// The component catalogue: every SDK component in its states, under a theme switch. Open it in an Xcode
/// preview, or embed it in an app's debug menu.
public struct ShowcaseView: View {
    @State private var themeID = Theme.standard.id
    @State private var toasts = ToastCenter()

    private let themes: [Theme] = [.standard, .showcaseBrand]

    public init() {}

    public var body: some View {
        let theme = themes.first { $0.id == themeID } ?? .standard

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    Picker("Theme", selection: $themeID) {
                        ForEach(themes) { Text($0.id.capitalized).tag($0.id) }
                    }
                    .pickerStyle(.segmented)

                    ShowcaseGallery(toasts: toasts)
                }
                .padding(theme.spacing.lg)
            }
            .themedBackground()
            .navigationTitle("WoW2 iOS")
        }
        .toastHost(toasts)
        .wow2Theme(theme)
    }
}

/// Every component once, without scroll or navigation chrome — what the render tests draw.
public struct ShowcaseGallery: View {
    private let toasts: ToastCenter

    @State private var isOn = true
    @State private var name = ""
    @State private var password = "secret"
    @State private var isLoading = true
    @State private var isSheetShown = false
    @State private var language = "en"
    @State private var quality = 1
    @State private var period = "week"
    @State private var isBannerShown = true

    @Environment(\.wow2Theme) private var theme

    public init(toasts: ToastCenter) {
        self.toasts = toasts
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
            SectionHeader("Buttons", subtitle: "ThemeButtonStyle · ActionButton")
            VStack(spacing: theme.spacing.sm) {
                ActionButton("Save", systemImage: "tray.and.arrow.down", isFullWidth: true) {
                    try? await Task.sleep(for: .seconds(1))
                    toasts.show("Saved", tone: .success)
                }
                HStack {
                    Button("Secondary") {}.buttonStyle(.theme(.secondary))
                    Button("Delete", role: .destructive) {}.buttonStyle(.theme(.destructive))
                    Button("Ghost") {}.buttonStyle(.theme(.ghost))
                }
                HStack {
                    Button("Busy") {}.buttonStyle(.theme(.primary, size: .small, isBusy: true))
                    Button("Disabled") {}.buttonStyle(.theme(.primary, size: .small)).disabled(true)
                    Button("Large") {}.buttonStyle(.theme(.secondary, size: .large))
                }
                SegmentedControl(selection: $period, options: [
                    SelectOption("Day", value: "day"),
                    SelectOption("Week", value: "week"),
                    SelectOption("Month", value: "month"),
                ])
                SegmentedControl(selection: $quality, options: [
                    SelectOption("Photo", value: 0, systemImage: "camera"),
                    SelectOption("Video", value: 1, systemImage: "video"),
                ])
            }

            SectionHeader("Badges", subtitle: "Badge · tone × soft, solid, outline")
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                ForEach(BadgeVariant.allCases, id: \.self) { variant in
                    FlowRow(spacing: theme.spacing.sm) {
                        ForEach(BadgeTone.allCases, id: \.self) { tone in
                            Badge(tone.rawValue.capitalized, tone: tone, variant: variant)
                        }
                    }
                }
                HStack(spacing: theme.spacing.sm) {
                    Badge("Live", tone: .success, showsDot: true)
                    Badge("Offline", tone: .neutral, variant: .outline, showsDot: true)
                    Badge("Failed", tone: .danger, variant: .solid, size: .small, showsDot: true)
                    Badge("Pro", tone: .primary, systemImage: "star.fill")
                }
            }

            SectionHeader("Avatars")
            HStack(spacing: theme.spacing.md) {
                Avatar("Ada Lovelace", size: .small)
                Avatar("Grace Hopper", size: .medium, tone: .primary)
                Avatar("Alan Turing", size: .large, tone: .success)
                Avatar("Katherine Johnson", size: .extraLarge, shape: .square, tone: .warning)
                Avatar("", size: .medium, tone: .danger)
            }

            SectionHeader("Cards")
            ForEach(CardVariant.allCases, id: \.self) { variant in
                Card(variant: variant) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(variant.rawValue.capitalized).font(theme.typography.heading.font)
                        Text("Content reads the card's tokens.").font(theme.typography.body.font)
                    }
                }
            }

            SectionHeader("Form")
            TextInput("Name", text: $name, prompt: "Ada Lovelace", message: "Shown on your profile.")
            TextInput("Password", text: $password, error: "At least 12 characters.", isSecure: true)

            ListGroup("Settings", footer: "Rows paint the card fill; the border shows between them.") {
                SwitchField("Notifications", description: "Shoot reminders", systemImage: "bell", isOn: $isOn)
                ListGroupItem("Language", systemImage: "globe") { Text("English") }
                ListGroupItem("Show a sheet", systemImage: "rectangle.bottomhalf.inset.filled") {
                    isSheetShown = true
                }
            }

            ListGroup(String("Inset separators"), footer: String("Strings render verbatim."), separator: .inset) {
                SelectField(
                    String("Language"),
                    description: String("Coach voice and captions"),
                    systemImage: "globe",
                    selection: $language,
                    options: [
                        SelectOption(String("English"), value: "en"),
                        SelectOption(String("Deutsch"), value: "de"),
                        SelectOption(String("Русский"), value: "ru"),
                    ]
                )
                SwitchField(String("Haptics"), systemImage: "hand.tap", isOn: $isOn)
                ListGroupItem(String("Version"), systemImage: "info.circle") { Text(verbatim: "0.0.2") }
            }

            SectionHeader("Feedback") {
                Button("Toast") { toasts.show("Heads up", message: "A second line.", tone: .info) }
                    .buttonStyle(.theme(.ghost, size: .small))
            }
            ForEach(ToastTone.allCases, id: \.self) { tone in
                Toast(ToastMessage(tone.rawValue.capitalized, message: "Toast tone", tone: tone))
            }

            if isBannerShown {
                Banner(
                    tone: .warning,
                    title: "Storage almost full",
                    message: "Free up space to keep saving shoots.",
                    actionTitle: "Manage storage",
                    action: {},
                    onDismiss: { isBannerShown = false }
                )
            }
            ForEach(BannerTone.allCases, id: \.self) { tone in
                Banner(tone: tone, message: String("\(tone.rawValue.capitalized) banner message."))
            }

            VStack(alignment: .leading, spacing: theme.spacing.md) {
                ProgressBar(value: 0.4, label: "Uploading")
                ProgressBar(value: 0.75, tone: .success, size: .large)
                ProgressBar(value: 0.2, tone: .danger, size: .small)
                ProgressBar(value: nil, tone: .neutral)
            }

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Skeleton(width: 180, height: 20)
                Skeleton(height: 14)
                Text("A paragraph that loads").skeleton(isLoading)
            }

            EmptyState("No photos yet", systemImage: "photo.on.rectangle", message: "Shoot one to see it here.") {
                Button("Open camera") {}.buttonStyle(.theme(.primary))
            }

            FeedbackActionsShowcase()
            SelectionShowcase()
            DisplayLayoutShowcase()
        }
        .sheet(isPresented: $isSheetShown) {
            VStack(alignment: .leading) {
                SheetHeader("Sheet title", description: "SheetHeader dismisses the sheet.")
                Spacer()
            }
            .themedBackground()
            .presentationDetents([.medium])
        }
    }
}

/// Lays badges out left to right, wrapping to a new line when the width runs out.
private struct FlowRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        for (index, point) in rows.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (points: [CGPoint], width: CGFloat, height: CGFloat) {
        let gap = spacing
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + gap
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + gap
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - gap)
        }
        return (points, widest, y + rowHeight)
    }
}

#Preview("Light") {
    ShowcaseView()
}

#Preview("Dark") {
    ShowcaseView().preferredColorScheme(.dark)
}
