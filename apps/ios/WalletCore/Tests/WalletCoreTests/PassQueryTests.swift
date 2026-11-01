import XCTest
@testable import WalletCore

final class PassQueryTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    var passes: [WalletPass] { SampleData.passes(now: now) }

    func testSearchMatchesTitleAndIssuerCaseAndDiacriticInsensitive() {
        XCTAssertEqual(PassQuery(text: "cafe").apply(to: passes).map(\.title), ["Rewards"]) // "Café"
        XCTAssertEqual(PassQuery(text: "SAMPLE AIR").apply(to: passes).count, 1)
        XCTAssertEqual(PassQuery(text: "rewards").apply(to: passes).count, 1)
    }

    func testCategoryFilterAndClear() {
        var q = PassQuery(text: "zzz", category: .loyalty)
        XCTAssertTrue(q.isFiltering); XCTAssertTrue(q.apply(to: passes).isEmpty)
        q.clearFilters()
        XCTAssertFalse(q.isFiltering); XCTAssertEqual(q.apply(to: passes).count, 7)
    }

    func testArchivedScope() {
        var all = passes; all[0].status = .archived
        XCTAssertEqual(PassQuery(scope: .archived).apply(to: all).count, 1)
        XCTAssertEqual(PassQuery(scope: .active).apply(to: all).count, 6)
    }

    func testSortRecentlyAddedNewestFirst() {
        let r = PassQuery(sort: .recentlyAdded).apply(to: passes)
        XCTAssertEqual(r.first?.title, "Demo Card"); XCTAssertEqual(r.last?.title, "Rewards")
    }

    func testSortByExpirySoonestFirstNoExpiryLast() {
        let r = PassQuery(sort: .expiry).apply(to: passes)
        XCTAssertEqual(r.first?.title, "Day Pass") // already expired = earliest
        XCTAssertNil(r.last?.validity.expiresAt)
    }

    func testSortByTitleIsStable() {
        let a = PassQuery(sort: .title).apply(to: passes), b = PassQuery(sort: .title).apply(to: passes.reversed())
        XCTAssertEqual(a, b)
    }
}
