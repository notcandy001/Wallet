import XCTest
@testable import WalletCore

final class PersistenceTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    var dir: URL!
    var file: URL { dir.appendingPathComponent("passes.json") }

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("wallet-tests-\(UUID().uuidString)")
    }
    override func tearDown() { try? FileManager.default.removeItem(at: dir) }

    func testMissingFileLoadsEmpty() async throws {
        let s = try await JSONPassRepository(fileURL: file).load()
        XCTAssertTrue(s.passes.isEmpty); XCTAssertFalse(s.didSeedSamples); XCTAssertFalse(s.recoveredFromCorruption)
    }

    func testCreateReadUpdateDeleteSurviveRelaunch() async throws {
        let repo = JSONPassRepository(fileURL: file)
        var pass = try PassDraft(category: .membership, title: "Gym", issuer: "Club").makePass(now: now)
        try await repo.upsert(pass)
        pass.title = "Gym 2"; try await repo.upsert(pass)

        let relaunched = try await JSONPassRepository(fileURL: file).load()
        XCTAssertEqual(relaunched.passes, [pass])

        try await repo.remove(id: pass.id)
        let after = try await JSONPassRepository(fileURL: file).load()
        XCTAssertTrue(after.passes.isEmpty)
    }

    func testArchivePersists() async throws {
        let repo = JSONPassRepository(fileURL: file)
        var p = try PassDraft(title: "A", issuer: "B").makePass(now: now)
        p.status = .archived; try await repo.upsert(p)
        let s = try await JSONPassRepository(fileURL: file).load()
        XCTAssertEqual(s.passes.first?.status, .archived)
    }

    func testSeedingHappensOnceAndNotAfterDeleteAll() async throws {
        let repo = JSONPassRepository(fileURL: file)
        try await repo.seedSamples(SampleData.passes(now: now))
        try await repo.seedSamples(SampleData.passes(now: now)) // no duplicates
        var s = try await JSONPassRepository(fileURL: file).load()
        XCTAssertEqual(s.passes.count, 7); XCTAssertTrue(s.didSeedSamples)
        try await repo.removeAll()
        s = try await JSONPassRepository(fileURL: file).load()
        XCTAssertTrue(s.passes.isEmpty); XCTAssertTrue(s.didSeedSamples)
    }

    func testCorruptFileIsQuarantinedNotDeleted() async throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: file)
        let s = try await JSONPassRepository(fileURL: file).load()
        XCTAssertTrue(s.recoveredFromCorruption); XCTAssertTrue(s.passes.isEmpty)
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(names.contains { $0.hasPrefix("passes.corrupt-") })
    }

    func testNewerSchemaIsNotTouched() async throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let bytes = Data(#"{"schemaVersion": 99, "future": true}"#.utf8)
        try bytes.write(to: file)
        do { _ = try await JSONPassRepository(fileURL: file).load(); XCTFail("expected throw") }
        catch { XCTAssertEqual(error as? RepositoryError, .unsupportedSchema(found: 99)) }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testExportContainsPasses() throws {
        let data = try PassExporter.export(SampleData.passes(now: now), now: now)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("Bean & Leaf")); XCTAssertTrue(text.contains("\"sample\""))
    }

    func testSamplesAreAllSampleTrustAndUniqueIDs() {
        let s = SampleData.passes(now: now)
        XCTAssertTrue(s.allSatisfy { $0.trust == .sample })
        XCTAssertEqual(Set(s.map(\.id)).count, s.count)
    }
}
