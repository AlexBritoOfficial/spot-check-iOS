import XCTest
@testable import SpotCheck

/// Every client-facing Edge Function fails with `{ "error": ... }` and
/// sometimes a `message` (`_shared/http.ts`). These pin what the app shows
/// for each shape, so a machine code never reaches the screen.
final class EdgeFunctionErrorTests: XCTestCase {

    func testASentenceInErrorIsShownAsIs() {
        let error = EdgeFunctionError(
            statusCode: 403,
            body: json(#"{"error":"Only verified filmers and pros can set up payouts."}"#)
        )

        XCTAssertEqual(error.code, "Only verified filmers and pros can set up payouts.")
        XCTAssertEqual(error.userMessage, "Only verified filmers and pros can set up payouts.")
    }

    func testMessageWinsOverAMachineCode() {
        let error = EdgeFunctionError(
            statusCode: 409,
            body: json(#"{"error":"payouts_not_ready","message":"Finish setting up payouts before delivering, so this can be paid out."}"#)
        )

        XCTAssertEqual(error.code, "payouts_not_ready")
        XCTAssertEqual(error.userMessage, "Finish setting up payouts before delivering, so this can be paid out.")
    }

    func testABareMachineCodeIsNeverShown() {
        let error = EdgeFunctionError(
            statusCode: 403,
            body: json(#"{"error":"identity_verification_required","requires":"identity"}"#)
        )

        XCTAssertEqual(error.code, "identity_verification_required")
        XCTAssertEqual(error.userMessage, EdgeFunctionError.genericMessage)
    }

    func testABodyThatIsNotJSONFallsBackToTheGenericMessage() {
        let error = EdgeFunctionError(statusCode: 502, body: Data("<html>Bad gateway</html>".utf8))

        XCTAssertNil(error.code)
        XCTAssertEqual(error.userMessage, EdgeFunctionError.genericMessage)
    }

    func testA401AsksTheUserToSignInAgain() {
        let error = EdgeFunctionError(statusCode: 401, body: json(#"{"error":"Not signed in."}"#))

        XCTAssertTrue(error.isNotSignedIn)
        XCTAssertEqual(error.userMessage, "Your session has expired. Sign in again to continue.")
    }

    private func json(_ string: String) -> Data { Data(string.utf8) }
}
