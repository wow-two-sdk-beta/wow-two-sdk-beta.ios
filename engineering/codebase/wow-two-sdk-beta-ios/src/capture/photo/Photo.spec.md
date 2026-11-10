# Photo

Imports a picked photo as a bounded working image, encodes a JPEG, and adds it to the photo library.

Source: [PhotoImport.swift](PhotoImport.swift), [JpegExport.swift](JpegExport.swift),
[PhotoLibrary.swift](PhotoLibrary.swift), [UIImage+Upright.swift](UIImage+Upright.swift).
Public import: `import WoW2IosCapture` (never through the `WoW2Ios` umbrella). fe sdk: none.

## Contract

- `PhotoImport.read` streams at most the byte budget plus one byte, so an oversized pick never lands in memory.
- `PhotoImport.decode` checks bytes and pixels from the header first, then decodes a thumbnail with the EXIF
  orientation applied and the longest side at most `workingDimension` (default 3000).
- `ImportedPhoto` reads the picker's temporary file inside the transfer, before the provider deletes it.
- `JpegExport.jpegData` returns nil rather than throwing; quality defaults to 0.92.
- `PhotoLibrary.save` asks for add-only access — never read access — and throws `SaveError.denied` without it.
- `UIImage.uprightImage(maxDimension:)` bakes the orientation into an sRGB bitmap at scale 1.
- Failure messages are English and describe the default budgets; an app localizes them as catalogue keys.

## API

| Member | Does |
|---|---|
| `PhotoImport.read(_:maximumBytes:)` | the bounded bytes of a file |
| `PhotoImport.decode(_:workingDimension:maximumBytes:maximumPixels:)` | an upright, downsampled `CGImage` |
| `PhotoImport.Failure` | `unreadable` · `tooLarge`, with `message` |
| `ImportedPhoto` | the `Transferable` a `PhotosPicker` item loads |
| `JpegExport.jpegData(from:quality:)` | JPEG bytes, or nil |
| `PhotoLibrary.save(_:)` | adds encoded image bytes to Photos |
| `UIImage.uprightImage(maxDimension:)` | an upright, capped bitmap |

## Verification

- [PhotoTests.swift](../../../tests/unit/capture/photo/PhotoTests.swift).
- `PhotoLibrary.save` needs the Photos permission prompt; it is checked in the consuming app.
