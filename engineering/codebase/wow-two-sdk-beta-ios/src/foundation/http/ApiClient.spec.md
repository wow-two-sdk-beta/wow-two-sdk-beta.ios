# ApiClient

Calls a be sdk host and returns a typed result: the success envelope's `data`, or a display-safe failure.

Source: [ApiClient.swift](ApiClient.swift), [ApiRequest.swift](ApiRequest.swift), [ApiFailure.swift](ApiFailure.swift), [ProblemDetails.swift](ProblemDetails.swift), [FieldError.swift](FieldError.swift), [ApiJson.swift](ApiJson.swift), [HttpTransport.swift](HttpTransport.swift), [JsonValue.swift](JsonValue.swift).

Public import: `import WoW2IosFoundation`. be sdk: `Web.Contracts.ApiResponse<T>`, `Foundation.Validation.FieldError`, `Web.ProblemDetails`. fe sdk: `foundation/http`.

## Contract

- `send` never throws: `ApiResult<T>` is `Result<ApiSuccess<T>, ApiFailure>`. `data(_:)` throws `ApiFailure` for `try await` sites.
- A 2xx body decodes as `{ "data": T, "warnings"?: [FieldError] }`; `warnings` reach `ApiSuccess.warnings`.
- `NoContent` accepts a 204 or an empty body.
- A non-2xx body decodes as problem details when it can; `errors` reads the be sdk's array and ASP.NET's `{ field: [messages] }` map.
- A 400 or 422 with field errors is `code: .validation`; any other non-2xx is `.http`; `kind` maps the status (401 `unauthorized` … 503 `unavailable`).
- `URLError.timedOut` → `.timeout`; cancellation → `.cancelled`; any other throw → `.transport` (`kind: .unavailable`).
- A 2xx body that is not the envelope → `.decoding`.
- `ApiFailure.message` is safe to show: the server's `detail`, its `title`, or a line per kind.
- Dates decode ISO 8601 with up to 7 fractional digits and `Z` or an offset; encode with milliseconds.
- `headers` runs before every request — the bearer token seam; per-request headers win.
- A query written into the path joins `query`; the log line carries `METHOD /path` only, never the query.

## API

| Member | Meaning |
|---|---|
| `ApiClient(baseURL:transport:timeout:headers:log:)` | `transport` defaults to `URLSession.shared`, `timeout` to 30 s. |
| `send(_:) async -> ApiResult<T>` | Sends and decodes. |
| `data(_:) async throws(ApiFailure) -> T` | The payload alone. |
| `ApiRequest.get` · `.delete` · `.post` · `.put` · `.patch` · `.send` | Builders; body builders encode JSON and throw on encoding failure. |
| `ApiFailure.fieldErrors` | Field errors keyed by property. |
| `HttpTransport` | The seam a test stub implements. |

## Verification

- [ApiClientTests.swift](../../../tests/unit/foundation/http/ApiClientTests.swift) against [StubTransport.swift](../../../tests/support/StubTransport.swift).
