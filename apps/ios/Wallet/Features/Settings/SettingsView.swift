import SwiftUI

struct SettingsView: View {
    @Environment(WalletModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @State private var exportURL: URL?
    @State private var exportFailed = false
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceRaw) {
                        ForEach(Appearance.allCases) { Text($0.title).tag($0.rawValue) }
                    }.pickerStyle(.segmented)
                }
                Section("Privacy") {
                    Text("Your passes are stored only on this device. Wallet has no account, no servers and no analytics, and sends nothing off your device.")
                        .font(.footnote)
                    Text("Wallet does not make payments, and passes shown here are not verified by their issuers unless marked Verified.")
                        .font(.footnote)
                }
                Section {
                    if let exportURL {
                        ShareLink(item: exportURL) { Label("Share export file", systemImage: "square.and.arrow.up") }
                    } else {
                        Button("Prepare export") { prepareExport() }
                    }
                    Button("Delete all data", role: .destructive) { confirmDeleteAll = true }
                } header: {
                    Text("Your data")
                } footer: {
                    Text("The export is a JSON file containing all your passes, including identifiers. Keep it somewhere safe.")
                }
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    LabeledContent("Product", value: Brand.name)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Delete all passes?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { Task { await model.deleteAll(); exportURL = nil } }
            } message: { Text("This removes every pass from this device and can't be undone. It does not revoke passes with their issuers.") }
            .alert("Couldn't prepare export", isPresented: $exportFailed) { Button("OK", role: .cancel) {} }
        }
    }

    private func prepareExport() {
        do { exportURL = try model.exportFile() } catch { exportFailed = true }
    }
}

extension Bundle {
    var appVersion: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}
