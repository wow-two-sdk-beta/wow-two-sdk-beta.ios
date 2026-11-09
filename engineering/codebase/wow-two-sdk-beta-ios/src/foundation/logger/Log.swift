import Foundation
import os

/// A log severity, mapped onto the unified logging system's levels.
public enum LogLevel: Int, Sendable, Hashable, Comparable, CaseIterable {
    case debug, info, notice, warning, error, fault

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var osType: OSLogType {
        switch self {
        case .debug: .debug
        case .info: .info
        case .notice: .default
        case .warning: .default
        case .error: .error
        case .fault: .fault
        }
    }
}

/// Whether a message may appear in clear text in a device log captured off the phone.
public enum LogPrivacy: Sendable, Hashable {
    /// Visible — identifiers, counts, statuses. Never a token, email or free text a user typed.
    case `public`
    /// Redacted as `<private>` outside a debugger.
    case `private`
}

/// One line a `Log` wrote, as a sink receives it.
public struct LogRecord: Sendable, Hashable {
    public var level: LogLevel
    public var subsystem: String
    public var category: String
    public var message: String
    public var date: Date
}

/// Receives every record a `Log` writes, beside the unified log — a test buffer, a crash-report breadcrumb trail.
public protocol LogSink: Sendable {
    func write(_ record: LogRecord)
}

/// Keeps records in memory, for tests and an in-app diagnostics screen.
public final class MemoryLogSink: LogSink {
    private let state = OSAllocatedUnfairLock<[LogRecord]>(initialState: [])
    private let limit: Int

    public init(limit: Int = 500) {
        self.limit = limit
    }

    public func write(_ record: LogRecord) {
        state.withLock { records in
            records.append(record)
            if records.count > limit { records.removeFirst(records.count - limit) }
        }
    }

    public var records: [LogRecord] { state.withLock { $0 } }
}

/// A category logger over `os.Logger`: one per feature, `Log(category: "shoot")`. Messages default to public
/// because they are written by code; pass `privacy: .private` for anything a user typed or owns.
public struct Log: Sendable {
    public let subsystem: String
    public let category: String
    public let minimumLevel: LogLevel
    private let logger: Logger
    private let sink: (any LogSink)?

    /// The app's bundle identifier, or `wow2` outside a bundle.
    public static var defaultSubsystem: String { Bundle.main.bundleIdentifier ?? "wow2" }

    public init(
        category: String,
        subsystem: String = Log.defaultSubsystem,
        minimumLevel: LogLevel = .debug,
        sink: (any LogSink)? = nil
    ) {
        self.subsystem = subsystem
        self.category = category
        self.minimumLevel = minimumLevel
        self.sink = sink
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    /// The underlying logger, for per-argument privacy: `log.os.info("user \(id, privacy: .private)")`.
    public var os: Logger { logger }

    public func write(_ level: LogLevel, _ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        guard level >= minimumLevel else { return }
        let text = message()
        switch privacy {
        case .public: logger.log(level: level.osType, "\(text, privacy: .public)")
        case .private: logger.log(level: level.osType, "\(text, privacy: .private)")
        }
        sink?.write(LogRecord(level: level, subsystem: subsystem, category: category, message: text, date: Date()))
    }

    public func debug(_ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        write(.debug, message(), privacy: privacy)
    }

    public func info(_ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        write(.info, message(), privacy: privacy)
    }

    public func notice(_ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        write(.notice, message(), privacy: privacy)
    }

    public func warning(_ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        write(.warning, message(), privacy: privacy)
    }

    public func error(_ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        write(.error, message(), privacy: privacy)
    }

    public func fault(_ message: @autoclosure () -> String, privacy: LogPrivacy = .public) {
        write(.fault, message(), privacy: privacy)
    }
}
