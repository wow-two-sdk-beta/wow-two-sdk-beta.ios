@preconcurrency import CoreMotion
import Foundation
import Observation

/// Monitors headphone availability without requesting motion permission. Starts motion only while the app needs it.
@MainActor
@Observable
public final class HeadphoneGestures: NSObject, CMHeadphoneMotionManagerDelegate {
    public private(set) var isConnected = false
    public private(set) var authorization = CMHeadphoneMotionManager.authorizationStatus()
    @ObservationIgnored private let manager = CMHeadphoneMotionManager()
    @ObservationIgnored private var detector = HeadGestureDetector()
    @ObservationIgnored private var generation: UUID?
    @ObservationIgnored private var onGesture: (@MainActor (HeadGesture) -> Void)?

    public override init() {
        super.init()
        manager.delegate = self
    }

    public func observeConnection() {
        refreshAuthorization()
        guard !manager.isConnectionStatusActive else { return }
        manager.startConnectionStatusUpdates()
    }

    public func stopObservingConnection() {
        stop()
        manager.stopConnectionStatusUpdates()
        isConnected = false
    }

    public func start(onGesture: @escaping @MainActor (HeadGesture) -> Void) {
        refreshAuthorization()
        guard isConnected, manager.isDeviceMotionAvailable,
              authorization == .authorized || authorization == .notDetermined else { return }
        self.onGesture = onGesture
        guard generation == nil else { return }
        let token = UUID()
        generation = token
        detector = HeadGestureDetector()
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            let pose = motion.map { HeadPose(time: $0.timestamp, pitch: $0.attitude.pitch, yaw: $0.attitude.yaw) }
            let failed = error != nil
            // Core Motion delivers this closure on the main operation queue supplied above.
            MainActor.assumeIsolated {
                guard let self, self.generation == token else { return }
                self.refreshAuthorization()
                if failed { self.stop() }
                if let pose, let gesture = self.detector.receive(pose) { self.onGesture?(gesture) }
            }
        }
    }

    public func stop() {
        generation = nil
        onGesture = nil
        manager.stopDeviceMotionUpdates()
    }

    public func refreshAuthorization() {
        authorization = CMHeadphoneMotionManager.authorizationStatus()
    }

    public nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            guard let self, self.manager.isConnectionStatusActive else { return }
            self.isConnected = true
            self.refreshAuthorization()
        }
    }

    public nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.stop()
            self.isConnected = false
        }
    }
}
