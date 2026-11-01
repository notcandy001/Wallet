import Foundation
import Observation

@MainActor @Observable
final class WalletModel {
    enum LoadState: Equatable { case idle, loading, ready, failed(String) }
    enum SaveResult: Equatable { case saved, invalid([ValidationError]), failed }

    private(set) var passes: [WalletPass] = []
    private(set) var loadState: LoadState = .idle
    var query = PassQuery()
    var notice: String?

    private let repository: PassRepository
    private let clock: () -> Date

    init(repository: PassRepository, clock: @escaping () -> Date = { .now }) {
        self.repository = repository
        self.clock = clock
    }

    var now: Date { clock() }
    var visiblePasses: [WalletPass] { query.apply(to: passes) }
    var archivedCount: Int { passes.filter { $0.status == .archived }.count }

    func load() async {
        guard loadState == .idle else { return }
        loadState = .loading
        do {
            var snapshot = try await repository.load()
            if snapshot.recoveredFromCorruption {
                notice = String(localized: "Your saved data couldn't be read, so Wallet started fresh. The unreadable file was kept for diagnosis.")
            }
            if !snapshot.didSeedSamples {
                try await repository.seedSamples(SampleData.passes(now: clock()))
                snapshot = try await repository.load()
            }
            passes = snapshot.passes
            loadState = .ready
        } catch RepositoryError.unsupportedSchema {
            loadState = .failed(String(localized: "This data was created by a newer version of Wallet. Update the app to open it."))
        } catch {
            loadState = .failed(String(localized: "Couldn't open your wallet."))
        }
    }

    func save(_ draft: PassDraft, editing existing: WalletPass?) async -> SaveResult {
        do {
            let pass = try existing.map { try draft.applying(to: $0, now: clock()) } ?? draft.makePass(now: clock())
            try await repository.upsert(pass)
            replace(pass)
            return .saved
        } catch let e as ValidationErrors {
            return .invalid(e.errors)
        } catch {
            return .failed
        }
    }

    func setArchived(_ pass: WalletPass, _ archived: Bool) async {
        var p = pass
        p.status = archived ? .archived : .active
        p.updatedAt = clock()
        do { try await repository.upsert(p); replace(p) }
        catch { notice = String(localized: "Couldn't save your changes.") }
    }

    func delete(_ pass: WalletPass) async {
        do {
            try await repository.remove(id: pass.id)
            passes.removeAll { $0.id == pass.id }
        } catch { notice = String(localized: "Couldn't delete the pass.") }
    }

    func deleteAll() async {
        do { try await repository.removeAll(); passes = [] }
        catch { notice = String(localized: "Couldn't delete your data.") }
    }

    func exportFile() throws -> URL {
        let data = try PassExporter.export(passes, now: clock())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wallet-export.json")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    private func replace(_ pass: WalletPass) {
        if let i = passes.firstIndex(where: { $0.id == pass.id }) { passes[i] = pass } else { passes.append(pass) }
    }
}
