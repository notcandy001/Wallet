import XCTest
@testable import WalletCore

final class ValidationTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func valid() -> PassDraft { PassDraft(category: .loyalty, title: "Rewards", issuer: "Cafe") }

    func testValidDraftHasNoErrors() { XCTAssertTrue(valid().validate().isEmpty) }

    func testRequiredFields() {
        let errors = PassDraft().validate()
        XCTAssertTrue(errors.contains(.init(field: .title, code: .required)))
        XCTAssertTrue(errors.contains(.init(field: .issuer, code: .required)))
    }

    func testTooLongIsRejectedNotTruncated() {
        var d = valid(); d.title = String(repeating: "a", count: PassLimits.title + 1)
        XCTAssertEqual(d.validate(), [.init(field: .title, code: .tooLong)])
    }

    func testControlCharactersRejected() {
        var d = valid(); d.title = "Bad\u{0007}Title"
        XCTAssertEqual(d.validate(), [.init(field: .title, code: .invalidCharacters)])
        d = valid(); d.codePayload = "line1\nline2"
        XCTAssertEqual(d.validate(), [.init(field: .codePayload, code: .invalidCharacters)])
    }

    func testIdentifierCharacterSet() {
        var d = valid(); d.identifier = "AB-12_3.4/5 6"
        XCTAssertTrue(d.validate().isEmpty)
        d.identifier = "AB<script>"
        XCTAssertEqual(d.validate(), [.init(field: .identifier, code: .invalidCharacters)])
    }

    func testPayloadLimit() {
        var d = valid(); d.codePayload = String(repeating: "x", count: PassLimits.codePayload + 1)
        XCTAssertEqual(d.validate(), [.init(field: .codePayload, code: .tooLong)])
    }

    func testExpiryMustFollowStart() {
        var d = valid(); d.validFrom = now; d.expiresAt = now
        XCTAssertEqual(d.validate(), [.init(field: .validity, code: .invalidRange)])
    }

    func testFieldLimits() {
        var d = valid(); d.fields = (0...PassLimits.maxFields).map { PassField(label: "L\($0)", value: "v") }
        XCTAssertTrue(d.validate().contains(.init(field: .fields, code: .tooMany)))
        d.fields = [PassField(label: "", value: "v")]
        XCTAssertTrue(d.validate().contains(.init(field: .fields, code: .required)))
    }

    func testDraftAlwaysProducesCustomTrust() throws {
        let pass = try valid().makePass(now: now)
        XCTAssertEqual(pass.trust, .custom)
        XCTAssertEqual(pass.status, .active)
    }

    func testMakePassTrimsWhitespace() throws {
        var d = valid(); d.title = "  Rewards  "; d.identifier = "   "
        let p = try d.makePass(now: now)
        XCTAssertEqual(p.title, "Rewards"); XCTAssertNil(p.identifier)
    }

    func testEditingKeepsIdentityAndTrust() throws {
        let sample = SampleData.passes(now: now)[0]
        var d = PassDraft(from: sample); d.title = "Renamed"
        let updated = try d.applying(to: sample, now: now.addingTimeInterval(10))
        XCTAssertEqual(updated.id, sample.id); XCTAssertEqual(updated.trust, .sample)
        XCTAssertEqual(updated.createdAt, sample.createdAt); XCTAssertEqual(updated.title, "Renamed")
    }

    func testNonEditableTrustCannotBeEdited() {
        var p = SampleData.passes(now: now)[0]; p.trust = .imported
        XCTAssertFalse(p.isEditable)
        XCTAssertThrowsError(try PassDraft(from: p).applying(to: p, now: now))
    }

    func testMaskedIdentifier() {
        var p = SampleData.passes(now: now)[0]
        p.identifier = "AB-12-3456"; XCTAssertEqual(p.maskedIdentifier, "•••• 3456")
        p.identifier = "123"; XCTAssertEqual(p.maskedIdentifier, "••••")
        p.identifier = nil; XCTAssertNil(p.maskedIdentifier)
    }

    func testValidityBoundaries() {
        let v = PassValidity(validFrom: now, expiresAt: now.addingTimeInterval(100 * 86_400))
        XCTAssertEqual(v.state(at: now.addingTimeInterval(-1)), .notYetValid)
        XCTAssertEqual(v.state(at: now), .valid)
        XCTAssertEqual(v.state(at: now.addingTimeInterval(80 * 86_400)), .expiringSoon)
        XCTAssertEqual(v.state(at: now.addingTimeInterval(100 * 86_400)), .expired)
        XCTAssertEqual(PassValidity().state(at: now), .valid)
    }
}
