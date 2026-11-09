import Foundation

/// How much weight a field error carries — the be sdk's `ValidationSeverity`.
public enum ValidationSeverity: String, Sendable, Hashable, Codable {
    case error, warning, info

    /// Reads the camelCase label the be sdk writes, and the integer ordinal an unconfigured host writes.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let ordinal = try? container.decode(Int.self) {
            self = switch ordinal {
            case 1: .warning
            case 2: .info
            default: .error
            }
            return
        }
        let label = try container.decode(String.self).lowercased()
        self = ValidationSeverity(rawValue: label) ?? .error
    }
}

/// One field-level validation failure — the be sdk's `FieldError`, as it travels in a problem's `errors` array
/// and a success envelope's `warnings`.
public struct FieldError: Sendable, Hashable, Codable {
    /// The member path that failed, e.g. `Rules[0].Content.Url`.
    public var property: String
    /// The server's display message.
    public var message: String
    /// The stable rule code, e.g. `NotEmptyValidator`; empty when the server sent none.
    public var code: String
    /// The rule's operands — `MaxLength`, `ComparisonValue` — for re-rendering the message client-side.
    public var params: [String: JsonValue]?
    public var severity: ValidationSeverity

    public init(
        property: String,
        message: String,
        code: String = "",
        params: [String: JsonValue]? = nil,
        severity: ValidationSeverity = .error
    ) {
        self.property = property
        self.message = message
        self.code = code
        self.params = params
        self.severity = severity
    }

    private enum CodingKeys: String, CodingKey {
        case property, message, code, params, severity
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        property = try container.decodeIfPresent(String.self, forKey: .property) ?? ""
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        code = try container.decodeIfPresent(String.self, forKey: .code) ?? ""
        params = try container.decodeIfPresent([String: JsonValue].self, forKey: .params)
        severity = try container.decodeIfPresent(ValidationSeverity.self, forKey: .severity) ?? .error
    }
}
