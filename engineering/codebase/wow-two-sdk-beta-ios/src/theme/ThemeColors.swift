/// The four slots of one tone family — the fe sdk's `{tone}`, `{tone}-foreground`, `{tone}-soft`,
/// `{tone}-soft-foreground`.
public struct ToneColors: Sendable, Hashable {
    /// The solid fill.
    public var base: ColorToken
    /// Text and icons on `base`.
    public var foreground: ColorToken
    /// The tinted, low-emphasis fill.
    public var soft: ColorToken
    /// Text and icons on `soft`, and tone-coloured text on neutral surfaces.
    public var softForeground: ColorToken

    public init(base: ColorToken, foreground: ColorToken, soft: ColorToken, softForeground: ColorToken) {
        self.base = base
        self.foreground = foreground
        self.soft = soft
        self.softForeground = softForeground
    }
}

/// Names a tone family, for components that take a tone (`Toast`, `ActionButton`).
public enum Tone: String, Sendable, CaseIterable {
    case primary, accent, destructive, info, success, warning
}

/// The semantic colour contract: the fe sdk's 16 surface tokens and 6 tone families × 4 slots, camel-cased
/// (`muted-foreground` → `mutedForeground`). Components read only these; a theme supplies every one.
public struct ThemeColors: Sendable, Hashable {
    public var background: ColorToken
    public var foreground: ColorToken
    public var card: ColorToken
    public var cardForeground: ColorToken
    public var popover: ColorToken
    public var popoverForeground: ColorToken
    /// The form-field fill.
    public var field: ColorToken
    public var muted: ColorToken
    public var mutedForeground: ColorToken
    /// Small text and placeholders.
    public var subtleForeground: ColorToken
    public var inverse: ColorToken
    public var inverseForeground: ColorToken
    public var border: ColorToken
    public var borderStrong: ColorToken
    /// The form-field boundary.
    public var input: ColorToken
    /// The focus indicator.
    public var ring: ColorToken
    /// The translucent fill behind controls and text drawn over media — a camera viewfinder, a full-screen
    /// picture. It keeps one value in both modes, since the picture, not the colour scheme, sets the backdrop.
    public var scrim: ColorToken
    /// Text and icons on `scrim`.
    public var scrimForeground: ColorToken

    public var primary: ToneColors
    public var accent: ToneColors
    public var destructive: ToneColors
    public var info: ToneColors
    public var success: ToneColors
    public var warning: ToneColors

    public init(
        background: ColorToken, foreground: ColorToken,
        card: ColorToken, cardForeground: ColorToken,
        popover: ColorToken, popoverForeground: ColorToken,
        field: ColorToken,
        muted: ColorToken, mutedForeground: ColorToken, subtleForeground: ColorToken,
        inverse: ColorToken, inverseForeground: ColorToken,
        border: ColorToken, borderStrong: ColorToken, input: ColorToken, ring: ColorToken,
        scrim: ColorToken = ThemeColors.standardScrim, scrimForeground: ColorToken = ThemeColors.standardScrimForeground,
        primary: ToneColors, accent: ToneColors, destructive: ToneColors,
        info: ToneColors, success: ToneColors, warning: ToneColors
    ) {
        self.background = background
        self.foreground = foreground
        self.card = card
        self.cardForeground = cardForeground
        self.popover = popover
        self.popoverForeground = popoverForeground
        self.field = field
        self.muted = muted
        self.mutedForeground = mutedForeground
        self.subtleForeground = subtleForeground
        self.inverse = inverse
        self.inverseForeground = inverseForeground
        self.border = border
        self.borderStrong = borderStrong
        self.input = input
        self.ring = ring
        self.scrim = scrim
        self.scrimForeground = scrimForeground
        self.primary = primary
        self.accent = accent
        self.destructive = destructive
        self.info = info
        self.success = success
        self.warning = warning
    }

    /// The family `tone` names.
    public subscript(tone: Tone) -> ToneColors {
        get {
            switch tone {
            case .primary: primary
            case .accent: accent
            case .destructive: destructive
            case .info: info
            case .success: success
            case .warning: warning
            }
        }
        set {
            switch tone {
            case .primary: primary = newValue
            case .accent: accent = newValue
            case .destructive: destructive = newValue
            case .info: info = newValue
            case .success: success = newValue
            case .warning: warning = newValue
            }
        }
    }
}

extension ThemeColors {
    /// The default `scrim`: black at 60 % in both modes.
    public static let standardScrim = ColorToken("#00000099")
    /// The default `scrimForeground`: white in both modes.
    public static let standardScrimForeground = ColorToken("#ffffff")

    /// The fe sdk's default theme (`src/index.css` `@theme` and `.dark`), OKLCH values converted to sRGB hex.
    public static let standard = ThemeColors(
        background: ColorToken("#ffffff", "#09090b"),
        foreground: ColorToken("#18181b", "#fafafa"),
        card: ColorToken("#ffffff", "#18181b"),
        cardForeground: ColorToken("#18181b", "#fafafa"),
        popover: ColorToken("#ffffff", "#18181b"),
        popoverForeground: ColorToken("#18181b", "#fafafa"),
        field: ColorToken("#ffffff", "#09090b"),
        muted: ColorToken("#f4f4f5", "#18181b"),
        mutedForeground: ColorToken("#6d6d76", "#a1a1aa"),
        subtleForeground: ColorToken("#6f6f78", "#82828b"),
        inverse: ColorToken("#18181b", "#fafafa"),
        inverseForeground: ColorToken("#fafafa", "#09090b"),
        border: ColorToken("#e4e4e7", "#27272a"),
        borderStrong: ColorToken("#8d8d90", "#64646c"),
        input: ColorToken("#8d8d90", "#64646c"),
        ring: ColorToken("#3b82f6", "#60a5fa"),
        primary: ToneColors(
            base: ColorToken("#2563eb", "#3b82f6"),
            foreground: ColorToken("#ffffff", "#1e1e1e"),
            soft: ColorToken("#dbeafe", "#1e3a8a"),
            softForeground: ColorToken("#1645cf", "#dbeafe")
        ),
        accent: ToneColors(
            base: ColorToken("#0d9488", "#2dd4bf"),
            foreground: ColorToken("#1d1d1d", "#042f2e"),
            soft: ColorToken("#ccfbf1", "#134e4a"),
            softForeground: ColorToken("#115e59", "#5eead4")
        ),
        destructive: ToneColors(
            base: ColorToken("#dc2626", "#ef4444"),
            foreground: ColorToken("#ffffff", "#1c1c1c"),
            soft: ColorToken("#fef2f2", "#7f1d1d"),
            softForeground: ColorToken("#a7000c", "#fee2e2")
        ),
        info: ToneColors(
            base: ColorToken("#0e7490", "#06b6d4"),
            foreground: ColorToken("#ffffff", "#3c3c3c"),
            soft: ColorToken("#ecfeff", "#164e63"),
            softForeground: ColorToken("#005c74", "#cffafe")
        ),
        success: ToneColors(
            base: ColorToken("#16a34a", "#22c55e"),
            foreground: ColorToken("#272727", "#404040"),
            soft: ColorToken("#f0fdf4", "#14532d"),
            softForeground: ColorToken("#00692e", "#dcfce7")
        ),
        warning: ToneColors(
            base: ColorToken("#f59e0b", "#f59e0b"),
            foreground: ColorToken("#733008", "#733008"),
            soft: ColorToken("#fffbeb", "#78350f"),
            softForeground: ColorToken("#a14800", "#fef3c7")
        )
    )
}
