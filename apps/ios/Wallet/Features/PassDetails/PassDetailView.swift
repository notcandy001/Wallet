import SwiftUI

struct PassDetailView: View {
    @Environment(WalletModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let passID: UUID

    @State private var revealIdentifier = false
    @State private var confirmDelete = false
    @State private var editing = false

    private var pass: WalletPass? { model.passes.first { $0.id == passID } }

    var body: some View {
        Group {
            if let pass {
                ScrollView {
                    VStack(spacing: Space.l) {
                        PassCardView(pass: pass, now: model.now)
                        trustBox(pass)
                        if let payload = pass.codePayload { QRCodeView(payload: payload) }
                        details(pass)
                        actions(pass)
                    }
                    .padding(Space.m)
                }
                .background(Palette.background)
                .navigationTitle(pass.title)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $editing) { AddEditPassView(editing: pass) }
                .confirmationDialog("Delete this pass?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete from this device", role: .destructive) {
                        Task { await model.delete(pass); dismiss() }
                    }
                } message: {
                    Text("This only removes it from Wallet on this device. It does not cancel or revoke the pass with its issuer.")
                }
            } else {
                ContentUnavailableView("Pass not found", systemImage: "questionmark.folder")
            }
        }
    }

    private func trustBox(_ pass: WalletPass) -> some View {
        HStack(alignment: .top, spacing: Space.s) {
            Image(systemName: pass.trust == .verifiedCredential ? "checkmark.seal" : "info.circle").accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(pass.trust.label).font(.subheadline.weight(.semibold))
                Text(pass.trust.explanation).font(.footnote).foregroundStyle(.secondary)
                if pass.category == .paymentCardRepresentation {
                    Text("This is a visual representation only. It cannot make payments.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Space.m).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.control))
        .accessibilityElement(children: .combine)
    }

    private func details(_ pass: WalletPass) -> some View {
        VStack(spacing: 0) {
            row("Issuer", pass.issuer.name)
            row("Category", pass.category.plainTitle)
            if let id = pass.identifier {
                HStack {
                    Text("Identifier").foregroundStyle(.secondary)
                    Spacer()
                    Text(revealIdentifier ? id : (pass.maskedIdentifier ?? "")).monospacedDigit()
                    Button(revealIdentifier ? "Hide" : "Show") { revealIdentifier.toggle() }
                        .font(.footnote).buttonStyle(.borderless)
                }.padding(Space.m)
                Divider().padding(.leading, Space.m)
            }
            if let from = pass.validity.validFrom { row("Valid from", from.formatted(date: .abbreviated, time: .shortened)) }
            if let end = pass.validity.expiresAt { row("Expires", end.formatted(date: .abbreviated, time: .shortened)) }
            ForEach(pass.fields, id: \.self) { row($0.label, $0.value) }
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.control))
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).foregroundStyle(.secondary)
                Spacer(minLength: Space.m)
                Text(value).multilineTextAlignment(.trailing)
            }.padding(Space.m)
            Divider().padding(.leading, Space.m)
        }
        .accessibilityElement(children: .combine)
    }

    private func actions(_ pass: WalletPass) -> some View {
        VStack(spacing: Space.s) {
            if pass.isEditable {
                Button { editing = true } label: { Label("Edit", systemImage: "pencil").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
            }
            Button {
                Task { await model.setArchived(pass, pass.status == .active) ; if pass.status == .active { dismiss() } }
            } label: {
                Label(pass.status == .active ? "Archive" : "Restore", systemImage: pass.status == .active ? "archivebox" : "tray.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }.buttonStyle(.bordered)
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Delete", systemImage: "trash").frame(maxWidth: .infinity)
            }.buttonStyle(.bordered)
        }
        .controlSize(.large)
    }
}
