import AVKit
import SwiftUI

extension View {
    /// Routes volume buttons, Camera Control and (iOS 26) an AirPods stem click to `onPress` while `isEnabled`.
    ///
    /// Disabled, the buttons keep their system behaviour; volume-down changes the volume. `onPress` returns whether
    /// the press took a photo: on iOS 26 the default sound is off and the camera-shutter sound plays only then.
    /// Hardware capture events need iOS 18; below it the modifier does nothing.
    public func hardwareShutter(
        isEnabled: Bool,
        onPress: @escaping @MainActor (HardwareShutterPolicy.Phase) -> Bool
    ) -> some View {
        hardwareShutter(isEnabled: isEnabled, onPress: onPress, onEvent: nil)
    }

    /// Reports each delivered event, including phases that `onPress` ignores.
    public func hardwareShutter(
        isEnabled: Bool,
        onPress: @escaping @MainActor (HardwareShutterPolicy.Phase) -> Bool,
        onEvent: (@MainActor (HardwareShutterEvent) -> Void)?
    ) -> some View {
        modifier(HardwareShutterModifier(isEnabled: isEnabled, onPress: onPress, onEvent: onEvent))
    }
}

private struct HardwareShutterModifier: ViewModifier {
    let isEnabled: Bool
    let onPress: @MainActor (HardwareShutterPolicy.Phase) -> Bool
    let onEvent: (@MainActor (HardwareShutterEvent) -> Void)?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // The default sound is replaced by the camera-shutter sound, played only when a photo is taken.
            content.onCameraCaptureEvent(isEnabled: isEnabled, defaultSoundDisabled: true) { (event: AVCaptureEvent) in
                HardwareShutterEvent.dispatch(
                    phase: Self.phase(event.phase),
                    shouldPlaySound: event.shouldPlaySound,
                    onPress: onPress,
                    playSound: { event.play(.cameraShutter) },
                    onEvent: onEvent
                )
            }
        } else if #available(iOS 18.0, *) {
            content.onCameraCaptureEvent(isEnabled: isEnabled) { (event: AVCaptureEvent) in
                HardwareShutterEvent.dispatch(
                    phase: Self.phase(event.phase),
                    shouldPlaySound: false,
                    onPress: onPress,
                    onEvent: onEvent
                )
            }
        } else {
            content
        }
    }

    @available(iOS 18.0, *)
    private static func phase(_ phase: AVCaptureEventPhase) -> HardwareShutterPolicy.Phase {
        switch phase {
        case .began: .began
        case .ended: .ended
        default: .cancelled
        }
    }
}
