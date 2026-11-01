import Foundation

public struct WalletSnapshot: Sendable {
    public var passes: [WalletPass]
    public var didSeedSamples: Bool
    /// True when an unreadable store was moved aside and a fresh one started.
    public var recoveredFromCorruption: Bool
}

public enum RepositoryError: Error, Equatable {
    /// The file was written by a newer app version. It is left untouched.
    case unsupportedSchema(found: Int)
}

public protocol PassRepository: Sendable {
    func load() async throws -> WalletSnapshot
    func upsert(_ pass: WalletPass) async throws
    func remove(id: UUID) async throws
    func removeAll() async throws
    /// Inserts the samples and records that seeding happened, in one write.
    func seedSamples(_ passes: [WalletPass]) async throws
}

/// Single-file JSON store with atomic writes. See docs/decisions/0002-local-persistence.md.
public actor JSONPassRepository: PassRepository {
    public static let currentSchema = 1

    private struct Header: Decodable { let schemaVersion: Int }
    private struct Envelope: Codable {
        var schemaVersion: Int
        var didSeedSamples: Bool
        var passes: [WalletPass]
    }

    private let url: URL
    private var envelope: Envelope?
    private var recovered = false

    public init(fileURL: URL) { self.url = fileURL }

    private static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys, .prettyPrinted]; return e
    }
    private static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }

    public func load() throws -> WalletSnapshot {
        let env = try current()
        let flag = recovered
        recovered = false
        return WalletSnapshot(passes: env.passes, didSeedSamples: env.didSeedSamples, recoveredFromCorruption: flag)
    }

    public func upsert(_ pass: WalletPass) throws {
        var env = try current()
        if let i = env.passes.firstIndex(where: { $0.id == pass.id }) { env.passes[i] = pass } else { env.passes.append(pass) }
        try persist(env)
    }

    public func remove(id: UUID) throws {
        var env = try current()
        env.passes.removeAll { $0.id == id }
        try persist(env)
    }

    /// Deletes every pass but keeps the seeded flag so samples do not return.
    public func removeAll() throws {
        var env = try current()
        env.passes = []
        try persist(env)
    }

    public func seedSamples(_ passes: [WalletPass]) throws {
        var env = try current()
        guard !env.didSeedSamples else { return }
        env.passes.append(contentsOf: passes)
        env.didSeedSamples = true
        try persist(env)
    }

    private func current() throws -> Envelope {
        if let envelope { return envelope }
        let loaded = try readFromDisk()
        envelope = loaded
        return loaded
    }

    private func readFromDisk() throws -> Envelope {
        let fresh = Envelope(schemaVersion: Self.currentSchema, didSeedSamples: false, passes: [])
        guard FileManager.default.fileExists(atPath: url.path) else { return fresh }
        let data = try Data(contentsOf: url)
        if let header = try? Self.makeDecoder().decode(Header.self, from: data), header.schemaVersion > Self.currentSchema {
            throw RepositoryError.unsupportedSchema(found: header.schemaVersion)
        }
        do {
            return try Self.makeDecoder().decode(Envelope.self, from: data)
        } catch {
            // Keep the unreadable file for diagnosis rather than overwriting it.
            let stamp = Int(Date().timeIntervalSince1970)
            let aside = url.deletingLastPathComponent().appendingPathComponent("passes.corrupt-\(stamp).json")
            try? FileManager.default.moveItem(at: url, to: aside)
            recovered = true
            return fresh
        }
    }

    private func persist(_ env: Envelope) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try Self.makeEncoder().encode(env)
        #if os(iOS)
        let options: Data.WritingOptions = [.atomic, .completeFileProtection]
        #else
        let options: Data.WritingOptions = [.atomic]
        #endif
        try data.write(to: url, options: options)
        envelope = env
    }
}

/// In-memory repository for previews and tests.
public actor InMemoryPassRepository: PassRepository {
    private var passes: [WalletPass]
    private var seeded: Bool
    public init(passes: [WalletPass] = [], didSeedSamples: Bool = false) { self.passes = passes; self.seeded = didSeedSamples }
    public func load() -> WalletSnapshot { WalletSnapshot(passes: passes, didSeedSamples: seeded, recoveredFromCorruption: false) }
    public func upsert(_ pass: WalletPass) {
        if let i = passes.firstIndex(where: { $0.id == pass.id }) { passes[i] = pass } else { passes.append(pass) }
    }
    public func remove(id: UUID) { passes.removeAll { $0.id == id } }
    public func removeAll() { passes = [] }
    public func seedSamples(_ new: [WalletPass]) { guard !seeded else { return }; passes += new; seeded = true }
}

public enum PassExporter {
    /// JSON export of the given passes. Contains everything stored locally, including identifiers.
    public static func export(_ passes: [WalletPass], now: Date) throws -> Data {
        struct Export: Encodable { let exportedAt: Date; let schemaVersion: Int; let passes: [WalletPass] }
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; e.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try e.encode(Export(exportedAt: now, schemaVersion: JSONPassRepository.currentSchema, passes: passes))
    }
}
