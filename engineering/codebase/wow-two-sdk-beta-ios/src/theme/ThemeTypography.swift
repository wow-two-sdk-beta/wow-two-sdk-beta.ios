import SwiftUI

/// One text role: a Dynamic Type style plus weight and design, or a custom family scaled relative to that style.
public struct TypographyToken: Sendable, Hashable {
    public var style: Font.TextStyle
    public var weight: Font.Weight
    public var design: Font.Design
    /// A PostScript font name; `nil` keeps the system font. Scales with Dynamic Type relative to `style`.
    public var fontName: String?
    /// The point size `fontName` is drawn at before Dynamic Type scaling.
    public var size: CGFloat?

    public init(
        _ style: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        fontName: String? = nil,
        size: CGFloat? = nil
    ) {
        self.style = style
        self.weight = weight
        self.design = design
        self.fontName = fontName
        self.size = size
    }

    /// The SwiftUI font; it follows Dynamic Type in both the system and the custom form.
    public var font: Font {
        if let fontName {
            return Font.custom(fontName, size: size ?? Self.defaultSize(style), relativeTo: style).weight(weight)
        }
        return Font.system(style, design: design).weight(weight)
    }

    /// The same role in another design — `.rounded`, `.serif`, `.monospaced`.
    public func design(_ design: Font.Design) -> TypographyToken {
        var copy = self
        copy.design = design
        return copy
    }

    /// The large-size default points per text style (Apple HIG), used when a custom family sets no size.
    static func defaultSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}

/// The text roles components read — the fe sdk's `Heading` / `Text` / `LabelText` / `EyebrowText` / `CodeText`
/// mapped onto Dynamic Type.
public struct ThemeTypography: Sendable, Hashable {
    /// A screen's hero line.
    public var display: TypographyToken
    /// A screen or sheet title.
    public var title: TypographyToken
    /// A card or section heading.
    public var heading: TypographyToken
    /// Running text.
    public var body: TypographyToken
    /// Control labels — buttons, fields, rows.
    public var label: TypographyToken
    /// Helper text, descriptions, timestamps.
    public var caption: TypographyToken
    /// The small upper-case line above a heading.
    public var eyebrow: TypographyToken
    /// Code, identifiers, figures that must align.
    public var mono: TypographyToken

    public init(
        display: TypographyToken, title: TypographyToken, heading: TypographyToken, body: TypographyToken,
        label: TypographyToken, caption: TypographyToken, eyebrow: TypographyToken, mono: TypographyToken
    ) {
        self.display = display
        self.title = title
        self.heading = heading
        self.body = body
        self.label = label
        self.caption = caption
        self.eyebrow = eyebrow
        self.mono = mono
    }

    /// The system font in every role.
    public static let standard = ThemeTypography(
        display: TypographyToken(.largeTitle, weight: .bold),
        title: TypographyToken(.title2, weight: .semibold),
        heading: TypographyToken(.headline, weight: .semibold),
        body: TypographyToken(.body),
        label: TypographyToken(.subheadline, weight: .medium),
        caption: TypographyToken(.footnote),
        eyebrow: TypographyToken(.caption, weight: .semibold),
        mono: TypographyToken(.body, design: .monospaced)
    )

    /// Every role in `design`, `mono` excepted — one switch to a rounded or serif voice.
    public func design(_ design: Font.Design) -> ThemeTypography {
        ThemeTypography(
            display: display.design(design), title: title.design(design), heading: heading.design(design),
            body: body.design(design), label: label.design(design), caption: caption.design(design),
            eyebrow: eyebrow.design(design), mono: mono
        )
    }
}
