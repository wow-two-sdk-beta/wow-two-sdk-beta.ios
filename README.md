# wow-two-sdk-beta.ios

> ⚠️ **Beta-forever.** No semver, no API stability, no graduation roadmap. Ship fast, fix-forward.

The wow-two ios sdk: themed SwiftUI components and app foundations for WoW2 iOS apps, published as the Swift
package `WoW2SdkBetaIos` (iOS 17+, Swift 6).

| Product | Holds |
|---|---|
| `WoW2Ios` | everything below, one import |
| `WoW2IosFoundation` | `AppConfig` · `ApiClient` · `Log` · `AppLanguage` |
| `WoW2IosTheme` | `Theme` and its design tokens |
| `WoW2IosPresentation` | buttons · icon buttons · option tiles · cards · media card · badge · avatar · bullet list · list group · rows (switch, select, choice) · text input · banner · toast · spinner · loading and empty states · skeleton · media pill · action bar · top bar · sheet header |
| `WoW2IosCapture` | hardware shutter · photo import · library save · JPEG export — imported on its own, never through `WoW2Ios` |

## Install

Xcode → File → Add Package Dependencies → `https://github.com/wow-two-sdk-beta/wow-two-sdk-beta.ios` → Exact
Version. Or in a manifest:

```swift
.package(url: "https://github.com/wow-two-sdk-beta/wow-two-sdk-beta.ios", exact: "0.0.1"),
```

## Use

```swift
import SwiftUI
import WoW2Ios

@main
struct AcmeApp: App {
    @State private var toasts = ToastCenter()
    private let theme = Theme.standard.with(id: "acme") { $0.colors.primary.base = ColorToken("#7c3aed", "#a78bfa") }

    var body: some Scene {
        WindowGroup {
            RootView().toastHost(toasts).wow2Theme(theme)
        }
    }
}
```

Every SDK component below `.wow2Theme(_:)` reads that theme; change a token and they all follow.

## Develop

```bash
xcodebuild -scheme WoW2SdkBetaIos-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Layout and rules: [`CLAUDE.md`](CLAUDE.md) and [`engineering/engineering.md`](engineering/engineering.md).

## License

MIT
