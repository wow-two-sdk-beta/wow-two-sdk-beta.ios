# Capture controls

Use `CaptureControls` in camera apps that own an `AVCaptureSession`. The native implementation is available on iOS 18 and later. The session's serial queue owns the delegate, native controls and value mutations. Configure the queue and main-actor callbacks at initialization.

- `apply(_:to:device:)` installs controls in priority order up to the session limit. It ignores unsupported sessions, devices that cannot zoom and invalid slider or picker specs.
- Supply the localized title, an SF Symbol name and the permitted values. A discrete slider can include a value label format with the Apple `%@` placeholder.
- Changing only a selection updates the existing control. A new device or a change to the control definitions replaces the installed controls.
- Call `remove(from:)` on the same queue when the session stops. Hardware shutter handling stays in `HardwareShutter`.
