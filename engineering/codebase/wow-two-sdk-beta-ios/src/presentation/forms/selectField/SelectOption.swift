import SwiftUI

/// One choice of a `SelectField` or `SegmentedControl`: the value it stands for, its title and an optional SF
/// Symbol — the fe sdk's `{ value, label }` option.
public struct SelectOption<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: Text
    public let systemImage: String?

    public var id: Value { value }

    public init(_ title: LocalizedStringKey, value: Value, systemImage: String? = nil) {
        self.value = value
        self.title = Text(title)
        self.systemImage = systemImage
    }

    /// Renders `title` verbatim, with no localization lookup.
    @_disfavoredOverload
    public init<Title: StringProtocol>(_ title: Title, value: Value, systemImage: String? = nil) {
        self.value = value
        self.title = Text(title)
        self.systemImage = systemImage
    }
}
