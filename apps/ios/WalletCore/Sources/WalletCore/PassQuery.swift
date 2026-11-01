import Foundation

public struct PassQuery: Equatable, Sendable {
    public enum Scope: String, Sendable { case active, archived }
    public enum Sort: String, CaseIterable, Sendable { case recentlyAdded, title, expiry }

    public var text: String
    public var category: PassCategory?
    public var scope: Scope
    public var sort: Sort

    public init(text: String = "", category: PassCategory? = nil, scope: Scope = .active, sort: Sort = .recentlyAdded) {
        self.text = text; self.category = category; self.scope = scope; self.sort = sort
    }

    public var isFiltering: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty || category != nil }
    public mutating func clearFilters() { text = ""; category = nil }

    public func apply(to passes: [WalletPass]) -> [WalletPass] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let opts: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let filtered = passes.filter { pass in
            guard pass.status == (scope == .active ? .active : .archived) else { return false }
            if let category, pass.category != category { return false }
            if needle.isEmpty { return true }
            return pass.title.range(of: needle, options: opts) != nil
                || pass.issuer.name.range(of: needle, options: opts) != nil
        }
        return filtered.sorted(by: areInOrder)
    }

    private func areInOrder(_ a: WalletPass, _ b: WalletPass) -> Bool {
        func tieBreak() -> Bool {
            let c = a.title.localizedStandardCompare(b.title)
            return c == .orderedSame ? a.id.uuidString < b.id.uuidString : c == .orderedAscending
        }
        switch sort {
        case .recentlyAdded:
            return a.createdAt != b.createdAt ? a.createdAt > b.createdAt : tieBreak()
        case .title:
            return tieBreak()
        case .expiry:
            switch (a.validity.expiresAt, b.validity.expiresAt) {
            case let (x?, y?): return x != y ? x < y : tieBreak()
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return tieBreak()
            }
        }
    }
}
