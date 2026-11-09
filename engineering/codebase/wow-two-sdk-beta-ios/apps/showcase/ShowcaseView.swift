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

            SectionHeader("Feedback") {
                Button("Toast") { toasts.show("Heads up", message: "A second line.", tone: .info) }
                    .buttonStyle(.theme(.ghost, size: .small))
            }
            ForEach(ToastTone.allCases, id: \.self) { tone in
                Toast(ToastMessage(tone.rawValue.capitalized, message: "Toast tone", tone: tone))
            }

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Skeleton(width: 180, height: 20)
                Skeleton(height: 14)
                Text("A paragraph that loads").skeleton(isLoading)
            }

            EmptyState("No photos yet", systemImage: "photo.on.rectangle", message: "Shoot one to see it here.") {
                Button("Open camera") {}.buttonStyle(.theme(.primary))
            }
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

#Preview("Light") {
    ShowcaseView()
}

#Preview("Dark") {
    ShowcaseView().preferredColorScheme(.dark)
}
