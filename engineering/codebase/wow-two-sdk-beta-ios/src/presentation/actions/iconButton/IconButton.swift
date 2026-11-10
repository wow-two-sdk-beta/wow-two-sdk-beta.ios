import SwiftUI
import WoW2IosTheme

/// An icon-only button: an SF Symbol in a themed circle, a required VoiceOver label and a 44 pt hit target —
/// the native `Button` with `IconButtonStyle`. Supports `role` and `.disabled`.
public struct IconButton: View {
    private let label: Text
    private let systemImage: String
    private let variant: IconButtonVariant
    private let size: IconButtonSize
    private let role: ButtonRole?
    private let action: () -> Void

    /// - Parameter label: What VoiceOver reads; never shown.
    public init(
        systemImage: String,
        label: LocalizedStringKey,
        variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            text: Text(label), systemImage: systemImage, variant: variant, size: size, role: role, action: action
        )
    }

    /// Takes `label` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        systemImage: String,
        label: Title,
        variant: IconButtonVariant = .ghost,
        size: IconButtonSize = .medium,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            text: Text(label), systemImage: systemImage, variant: variant, size: size, role: role, action: action
        )
    }

    private init(
        text: Text,
        systemImage: String,
        variant: IconButtonVariant,
        size: IconButtonSize,
        role: ButtonRole?,
        action: @escaping () -> Void
    ) {
        self.label = text
        self.systemImage = systemImage
        self.variant = variant
        self.size = size
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            Label { label } icon: { Image(systemName: systemImage) }
        }
        .buttonStyle(IconButtonStyle(variant, size: size))
    }
}
