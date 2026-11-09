// swift-tools-version: 6.0
//
// The ios sdk (`WoW2SdkBetaIos`). SwiftPM reads a package manifest only at a git repository's root, so this
// manifest sits here and points every target into `engineering/codebase/wow-two-sdk-beta-ios/` with `path:` —
// the one file of the package kept outside its code dir (sdk-structure.md § Package boundary).
// Consumers pin a CI tag: `.package(url: "https://github.com/wow-two-sdk-beta/wow-two-sdk-beta.ios", exact: "0.0.1")`.

import Foundation
import PackageDescription

let codebase = "engineering/codebase/wow-two-sdk-beta-ios"

/// Every `.md` under `directory`, relative to it — specs sit beside their source and are not compiled.
func docs(in directory: String) -> [String] {
    let root = Context.packageDirectory + "/" + directory
    guard let walker = FileManager.default.enumerator(atPath: root) else { return [] }
    return walker.compactMap { $0 as? String }.filter { $0.hasSuffix(".md") }.sorted()
}

func target(_ name: String, _ directory: String, dependencies: [Target.Dependency] = []) -> Target {
    let path = "\(codebase)/\(directory)"
    return .target(name: name, dependencies: dependencies, path: path, exclude: docs(in: path))
}

func testTarget(_ name: String, _ directory: String, dependencies: [Target.Dependency]) -> Target {
    let path = "\(codebase)/\(directory)"
    return .testTarget(name: name, dependencies: dependencies, path: path, exclude: docs(in: path))
}

let package = Package(
    name: "WoW2SdkBetaIos",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WoW2Ios", targets: ["WoW2Ios"]),
        .library(name: "WoW2IosFoundation", targets: ["WoW2IosFoundation"]),
        .library(name: "WoW2IosTheme", targets: ["WoW2IosTheme"]),
        .library(name: "WoW2IosPresentation", targets: ["WoW2IosPresentation"]),
    ],
    targets: [
        // Layers: foundation (no UI) · theme (tokens) · presentation (components) · umbrella re-export.
        target("WoW2IosFoundation", "src/foundation"),
        target("WoW2IosTheme", "src/theme"),
        target("WoW2IosPresentation", "src/presentation", dependencies: ["WoW2IosTheme"]),
        target("WoW2Ios", "src/umbrella", dependencies: ["WoW2IosFoundation", "WoW2IosTheme", "WoW2IosPresentation"]),

        // Sandboxes: built and tested, never a product (sdk-structure.md § Apps).
        target("WoW2IosShowcase", "apps/showcase", dependencies: ["WoW2Ios"]),

        // Tests mirror `src/` under `tests/unit/`; shared fixtures sit in `tests/support/`.
        target("WoW2IosTestSupport", "tests/support", dependencies: ["WoW2IosFoundation"]),
        testTarget(
            "WoW2IosFoundationTests", "tests/unit/foundation",
            dependencies: ["WoW2IosFoundation", "WoW2IosTestSupport"]
        ),
        testTarget("WoW2IosThemeTests", "tests/unit/theme", dependencies: ["WoW2IosTheme"]),
        testTarget(
            "WoW2IosPresentationTests", "tests/unit/presentation",
            dependencies: ["WoW2IosPresentation", "WoW2IosShowcase"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
