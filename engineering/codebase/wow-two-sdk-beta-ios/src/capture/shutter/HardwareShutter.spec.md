# HardwareShutter

Takes a photo from a hardware press — a volume button, Camera Control, an AirPods stem click (iOS 26).

Source: [HardwareShutter.swift](HardwareShutter.swift), [HardwareShutterPolicy.swift](HardwareShutterPolicy.swift).
Public import: `import WoW2IosCapture` (never through the `WoW2Ios` umbrella). fe sdk: none.

## Contract

- `.hardwareShutter(isEnabled:onPress:)` wraps SwiftUI/AVKit `onCameraCaptureEvent`; disabled, the buttons keep their
  system behaviour.
- iOS 18+ only: below iOS 18 the modifier is a no-op and the buttons stay system buttons.
- iOS 26: the default capture sound is off; the camera-shutter sound plays only when `onPress` returns `true`.
- `HardwareShutterPolicy` is pure: `isActive` decides when to attach, `action(for:…)` what one press does.
- A press acts on release (`ended`), like the system Camera; `began` and `cancelled` are ignored.
- A press while the self-timer countdown is armed captures now and cancels the countdown.

## API

| Member | Does |
|---|---|
| `View.hardwareShutter(isEnabled:onPress:)` | routes hardware presses to `onPress` while enabled |
| `HardwareShutterPolicy.isActive(isEnabled:cameraReady:screenActive:)` | whether to attach the handler |
| `HardwareShutterPolicy.action(for:cameraReady:acceptsPhoto:countdownArmed:)` | `ignore` · `capture` · `captureCancellingCountdown` |
| `HardwareShutterPolicy.Phase` | `began` · `ended` · `cancelled` |

## Verification

- [HardwareShutterPolicyTests.swift](../../../tests/unit/capture/shutter/HardwareShutterPolicyTests.swift).
- The modifier needs a device with hardware buttons; it is checked in the consuming app.
