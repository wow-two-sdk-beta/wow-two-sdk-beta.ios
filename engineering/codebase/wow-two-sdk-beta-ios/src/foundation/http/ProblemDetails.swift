import Foundation

/// An RFC 9457 problem body as the be sdk writes it: the standard members plus `code`, `traceId` and the field
/// `errors` — the wow-two array shape or ASP.NET's `{ field: [messages] }` dictionary, both read into `errors`.
public struct ProblemDetails: Sendable, Hashable, Decodable {
    public var type: String?
    public var title: String?
    public var status: Int?
    public var detail: String?
    public var instance: String?
    /// The be sdk's `AppError` type, e.g. `Validation`, `NotFound`.
    public var code: String?
    public var traceId: String?
    /// Every field failure, grouped by nothing — `fieldErrors` groups them by property.
    public var errors: [FieldError]

    public init(
        type: String? = nil, title: String? = nil, status: Int? = nil, detail: String? = nil,
        instance: String? = nil, code: String? = nil, traceId: String? = nil, errors: [FieldError] = []
    ) {
        self.type = type
        self.title = title
        self.status = status
        self.detail = detail
        self.instance = instance
        self.code = code
        self.traceId = traceId
        self.errors = errors
    }

    private enum CodingKeys: String, CodingKey {
        case type, title, status, detail, instance, code, traceId, errors
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        status = try? container.decodeIfPresent(Int.self, forKey: .status)
        detail = try? container.decodeIfPresent(String.self, forKey: .detail)
        instance = try? container.decodeIfPresent(String.self, forKey: .instance)
        code = try? container.decodeIfPresent(String.self, forKey: .code)
        traceId = try? container.decodeIfPresent(String.self, forKey: .traceId)
        if let list = try? container.decodeIfPresent([FieldError].self, forKey: .errors) {
            errors = list
        } else if let map = try? container.decodeIfPresent([String: [String]].self, forKey: .errors) {
            errors = map.keys.sorted().flatMap { property in
                (map[property] ?? []).map { FieldError(property: property, message: $0) }
            }
        } else {
            errors = []
        }
    }

    /// The field failures keyed by property, in arrival order.
    public var fieldErrors: [String: [FieldError]] {
        Dictionary(grouping: errors, by: \.property)
    }
}
