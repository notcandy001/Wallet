import SwiftUI

@main
struct WalletApp: App {
    @State private var model = WalletModel(repository: JSONPassRepository(fileURL: WalletApp.storeURL))
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            WalletHomeView()
                .environment(model)
                .preferredColorScheme(Appearance(rawValue: appearanceRaw)?.scheme)
                .task { await model.load() }
        }
    }

    private static var storeURL: URL {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Wallet", isDirectory: true).appendingPathComponent("passes.json")
    }
}
