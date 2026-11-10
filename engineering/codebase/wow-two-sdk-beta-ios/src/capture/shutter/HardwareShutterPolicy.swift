import Foundation

/// When a hardware press (a volume button, Camera Control, an AirPods stem click) may take a photo, and what one does.
///
/// Adopting the capture-event handler removes the buttons' default behaviour, so attach it only while it can act.
public enum HardwareShutterPolicy {
    /// The stage of one press, mirroring the system's capture-event phase.
    public enum Phase: Equatable, Sendable {
        /// The button went down.
        case began
        /// The button came up: a completed press.
        case ended
        /// The system took the press away (an interruption, a lost focus).
        case cancelled
    }

    /// What one press does on a camera screen.
    public enum Action: Equatable, Sendable {
        /// Nothing: the press is not a completed one, or the camera cannot take a photo now.
        case ignore
        /// The on-screen shutter's capture.
        case capture
        /// The armed self-timer countdown is cancelled and the photo is taken now, in one step.
        case captureCancellingCountdown
    }

    /// Whether to attach the handler: the app allows it (`isEnabled`), the camera runs, and its screen is visible.
    ///
    /// Fold app conditions into `isEnabled` (a settings toggle, a mode that runs no capture session) — while the
    /// handler is detached, the buttons keep their system behaviour and volume-down changes the volume.
    public static func isActive(isEnabled: Bool, cameraReady: Bool, screenActive: Bool) -> Bool {
        isEnabled && cameraReady && screenActive
    }

    /// A press takes the photo on release, like the system Camera; a busy camera (capturing, processing,
    /// or holding a photo for review — `acceptsPhoto` false) ignores it.
    public static func action(for phase: Phase, cameraReady: Bool, acceptsPhoto: Bool, countdownArmed: Bool) -> Action {
        guard phase == .ended, cameraReady, acceptsPhoto else { return .ignore }
        return countdownArmed ? .captureCancellingCountdown : .capture
    }
}
