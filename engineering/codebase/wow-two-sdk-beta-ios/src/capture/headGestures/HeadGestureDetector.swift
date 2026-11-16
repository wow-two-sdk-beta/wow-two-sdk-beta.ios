import Foundation

public struct HeadPose: Equatable, Sendable {
    public let time: TimeInterval
    public let pitch: Double
    public let yaw: Double

    public init(time: TimeInterval, pitch: Double, yaw: Double) {
        self.time = time
        self.pitch = pitch
        self.yaw = yaw
    }
}

public enum HeadGesture: Equatable, Sendable {
    case nod
    case shake
}

/// Detects short, deliberate movements relative to a rolling rest position.
public struct HeadGestureDetector: Sendable {
    public struct Thresholds: Sendable {
        public var baselineWindow: TimeInterval = 1
        public var warmup: TimeInterval = 0.5
        public var excursion = 0.20
        public var returnTolerance = 0.08
        public var otherAxisLimit = 0.15
        public var nodWindow: TimeInterval = 1
        public var shakeWindow: TimeInterval = 1.4
        public var cooldown: TimeInterval = 1.2

        public init() {}
    }

    private struct Motion: Sendable {
        enum Kind: Sendable { case nod, shake(direction: Double) }
        let kind: Kind
        let startedAt: TimeInterval
        let pitch: Double
        let yaw: Double
    }

    private let thresholds: Thresholds
    private var firstTime: TimeInterval?
    private var lastTime: TimeInterval?
    private var cooldownUntil: TimeInterval?
    private var resting: [HeadPose] = []
    private var motion: Motion?

    public init(thresholds: Thresholds = .init()) {
        self.thresholds = thresholds
    }

    public mutating func receive(_ pose: HeadPose) -> HeadGesture? {
        guard pose.time.isFinite, pose.pitch.isFinite, pose.yaw.isFinite,
              lastTime.map({ pose.time > $0 }) ?? true else { return nil }
        lastTime = pose.time
        let first = firstTime ?? pose.time
        firstTime = first

        if pose.time - first < thresholds.warmup || cooldownUntil.map({ pose.time < $0 }) == true {
            remember(pose)
            return nil
        }

        if let motion { return continueMotion(motion, pose: pose) }
        resting.removeAll { $0.time < pose.time - thresholds.baselineWindow }
        guard !resting.isEmpty else { remember(pose); return nil }
        let pitch = resting.map(\.pitch).circularAverage
        let yaw = resting.map(\.yaw).circularAverage
        let pitchMovement = Self.distance(pose.pitch, from: pitch)
        let yawMovement = Self.distance(pose.yaw, from: yaw)

        if abs(pitchMovement) >= thresholds.excursion, abs(yawMovement) <= thresholds.otherAxisLimit {
            motion = Motion(kind: .nod, startedAt: pose.time, pitch: pitch, yaw: yaw)
        } else if abs(yawMovement) >= thresholds.excursion, abs(pitchMovement) <= thresholds.otherAxisLimit {
            motion = Motion(kind: .shake(direction: yawMovement < 0 ? -1 : 1),
                            startedAt: pose.time, pitch: pitch, yaw: yaw)
        } else {
            remember(pose)
        }
        return nil
    }

    private mutating func continueMotion(_ motion: Motion, pose: HeadPose) -> HeadGesture? {
        let pitch = Self.distance(pose.pitch, from: motion.pitch)
        let yaw = Self.distance(pose.yaw, from: motion.yaw)
        let elapsed = pose.time - motion.startedAt
        switch motion.kind {
        case .nod:
            if elapsed > thresholds.nodWindow || abs(yaw) > thresholds.otherAxisLimit {
                resetMotion(at: pose)
            } else if abs(pitch) <= thresholds.returnTolerance {
                return detected(.nod, at: pose)
            }
        case let .shake(direction):
            if elapsed > thresholds.shakeWindow || abs(pitch) > thresholds.otherAxisLimit {
                resetMotion(at: pose)
            } else if yaw * direction <= -thresholds.excursion {
                return detected(.shake, at: pose)
            }
        }
        return nil
    }

    private mutating func detected(_ gesture: HeadGesture, at pose: HeadPose) -> HeadGesture {
        cooldownUntil = pose.time + thresholds.cooldown
        resetMotion(at: pose)
        return gesture
    }

    private mutating func resetMotion(at pose: HeadPose) {
        motion = nil
        resting = [pose]
    }

    private mutating func remember(_ pose: HeadPose) {
        resting.removeAll { $0.time < pose.time - thresholds.baselineWindow }
        resting.append(pose)
    }

    private static func distance(_ angle: Double, from rest: Double) -> Double {
        let difference = angle - rest
        return atan2(sin(difference), cos(difference))
    }
}

private extension [Double] {
    var circularAverage: Double {
        atan2(reduce(0) { $0 + sin($1) }, reduce(0) { $0 + cos($1) })
    }
}
