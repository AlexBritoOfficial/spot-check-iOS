import Foundation
import Supabase

/// A non-2xx answer from one of `spot-check-backend`'s Edge Functions.
///
/// Every client-facing function fails the same way (`_shared/http.ts`): a JSON
/// body with an `error` field, which is either a sentence written for the user
/// ("Could not start verification.") or a machine code
/// ("identity_verification_required"), sometimes with a `message` beside it.
/// Only sentences are ever shown.
struct EdgeFunctionError: Error, Equatable, Sendable {
    static let genericMessage = "Something went wrong. Try again."

    let statusCode: Int
    /// The function's `error` field, when the body had one.
    let code: String?
    let message: String?

    init(statusCode: Int, body: Data) {
        self.statusCode = statusCode
        let decoded = try? JSONDecoder().decode(Body.self, from: body)
        code = decoded?.error
        message = decoded?.message
    }

    /// The gateway refuses an expired or missing JWT before the function runs.
    var isNotSignedIn: Bool { statusCode == 401 }

    var userMessage: String {
        if isNotSignedIn { return "Your session has expired. Sign in again to continue." }
        // Every function's own failure body has `error`. A body with only
        // `message` came from the gateway in front of them ("name resolution
        // failed"), which is written for operators, not users.
        guard let code else { return Self.genericMessage }
        if let message { return message }
        // A machine code is one word in snake_case; a sentence has spaces.
        return code.contains(" ") ? code : Self.genericMessage
    }

    private struct Body: Decodable {
        let error: String?
        let message: String?
    }
}

extension Error {
    /// What to show for any error thrown while calling a function: the
    /// function's own explanation if it sent one, otherwise a generic line
    /// rather than a URLError's or decoder's developer-facing text.
    var edgeFunctionUserMessage: String {
        (self as? EdgeFunctionError)?.userMessage ?? EdgeFunctionError.genericMessage
    }
}

extension FunctionsClient {
    /// Calls a function that takes no request body (POST, the client's
    /// default) and hands its response body to `decode`, turning a non-2xx
    /// answer into `EdgeFunctionError`. The signed-in user's JWT is attached
    /// by the client itself, which updates it on every auth event.
    func call<Response>(
        _ name: String,
        decode: (Data) throws -> Response
    ) async throws -> Response {
        do {
            return try await invoke(name) { data, _ in try decode(data) }
        } catch FunctionsError.httpError(let statusCode, let data) {
            throw EdgeFunctionError(statusCode: statusCode, body: data)
        }
    }

    /// The same, for a function that reads a JSON request body.
    func call<Response>(
        _ name: String,
        body: some Encodable,
        decode: (Data) throws -> Response
    ) async throws -> Response {
        do {
            return try await invoke(name, options: FunctionInvokeOptions(body: body)) { data, _ in
                try decode(data)
            }
        } catch FunctionsError.httpError(let statusCode, let data) {
            throw EdgeFunctionError(statusCode: statusCode, body: data)
        }
    }
}
