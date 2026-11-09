import SwiftUI
import WoW2IosTheme

/// A sheet's title row: title, optional description and a close button that dismisses the sheet — the fe sdk's
/// `OverlayHeader` with `OverlayTitle`, `OverlayDescription` and `OverlayCloseButton`.
public struct SheetHeader: View {
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let showsClose: Bool
    private let onClose: (@MainActor () -> Void)?

    @Environment(\.wow2Theme) private var theme
    @Environment(\.dismiss) private var dismiss

    /// - Parameter onClose: Runs instead of the environment's `dismiss`.
    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        showsClose: Bool = true,
        onClose: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.showsClose = showsClose
        self.onClose = onClose
    }

    public var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.title.font)
                    .foregroundStyle(theme.colors.foreground.color)
                    .accessibilityAddTraits(.isHeader)
                if let description {
                    Text(description)
                        .font(theme.typography.body.font)
                        .foregroundStyle(theme.colors.mutedForeground.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if showsClose {
                Button {
                    if let onClose { onClose() } else { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(theme.colors.mutedForeground.color)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(theme.colors.muted.color))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close"))
                .padding(.top, -theme.spacing.sm)
                .padding(.trailing, -theme.spacing.sm)
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.lg)
        .padding(.bottom, theme.spacing.sm)
    }
}
