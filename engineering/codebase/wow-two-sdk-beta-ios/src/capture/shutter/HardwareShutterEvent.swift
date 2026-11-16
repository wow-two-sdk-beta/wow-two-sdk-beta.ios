/// The result of handling one phase of a hardware capture event.
public struct HardwareShutterEvent: Sendable, Equatable {
    public let phase: HardwareShutterPolicy.Phase
    /// On iOS 26 and later, the system asks for a manual shutter sound on an AirPods stem click.
    public let isAirPodsClick: Bool
    /// Whether the app accepted the press and started a capture.
    public let tookPhoto: Bool
    /// Whether the system confirmed that it played the shutter sound.
    public let playedSound: Bool

    public init(phase: HardwareShutterPolicy.Phase, isAirPodsClick: Bool, tookPhoto: Bool, playedSound: Bool) {
        self.phase = phase
        self.isAirPodsClick = isAirPodsClick
        self.tookPhoto = tookPhoto
        self.playedSound = playedSound
    }

    @MainActor
    static func dispatch(
        phase: HardwareShutterPolicy.Phase,
        shouldPlaySound: Bool,
        onPress: @MainActor (HardwareShutterPolicy.Phase) -> Bool,
        playSound: () -> Bool = { false },
        onEvent: (@MainActor (HardwareShutterEvent) -> Void)?
    ) {
        let tookPhoto = onPress(phase)
        let playedSound = tookPhoto && shouldPlaySound && playSound()
        onEvent?(Self(phase: phase, isAirPodsClick: shouldPlaySound, tookPhoto: tookPhoto, playedSound: playedSound))
    }
}
