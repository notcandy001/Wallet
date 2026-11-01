import SwiftUI

struct AddEditPassView: View {
    @Environment(WalletModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let editing: WalletPass?

    @State private var draft: PassDraft
    @State private var errors: [ValidationError] = []
    @State private var hasStart: Bool
    @State private var hasExpiry: Bool
    @State private var isSaving = false
    @State private var saveFailed = false
    @FocusState private var focused: DraftField?

    init(editing: WalletPass?) {
        self.editing = editing
        let d = editing.map(PassDraft.init(from:)) ?? PassDraft()
        _draft = State(initialValue: d)
        _hasStart = State(initialValue: d.validFrom != nil)
        _hasExpiry = State(initialValue: d.expiresAt != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { preview }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                Section("Type") {
                    Picker("Category", selection: $draft.category) {
                        ForEach(PassCategory.allCases, id: \.self) { Text($0.plainTitle).tag($0) }
                    }
                }
                Section("Details") {
                    field("Title", text: $draft.title, field: .title)
                    field("Issuer", text: $draft.issuer, field: .issuer)
                    field("Identifier (optional)", text: $draft.identifier, field: .identifier, mono: true)
                }
                Section("Appearance") { colorPicker }
                Section("Validity") {
                    Toggle("Starts", isOn: $hasStart.animation())
                    if hasStart { DatePicker("Valid from", selection: Binding(get: { draft.validFrom ?? .now }, set: { draft.validFrom = $0 })) }
                    Toggle("Expires", isOn: $hasExpiry.animation())
                    if hasExpiry { DatePicker("Expires on", selection: Binding(get: { draft.expiresAt ?? .now.addingTimeInterval(86_400 * 365) }, set: { draft.expiresAt = $0 })) }
                    error(.validity)
                }
                Section("More details (optional)") {
                    ForEach(draft.fields.indices, id: \.self) { i in
                        HStack {
                            TextField("Label", text: $draft.fields[i].label)
                            TextField("Value", text: $draft.fields[i].value).multilineTextAlignment(.trailing)
                        }
                    }
                    .onDelete { draft.fields.remove(atOffsets: $0) }
                    if draft.fields.count < PassLimits.maxFields {
                        Button("Add detail") { draft.fields.append(PassField(label: "", value: "")) }
                    }
                    error(.fields)
                }
                Section {
                    field("QR text (optional)", text: $draft.codePayload, field: .codePayload, mono: true)
                } header: { Text("QR code") } footer: {
                    Text("Don't put passwords, PINs or sensitive personal information in a QR code. Anyone who scans it can read it.")
                }
            }
            .navigationTitle(editing == nil ? "New pass" : "Edit pass")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }.disabled(isSaving)
                }
            }
            .alert("Couldn't save", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Your changes were not stored. Please try again.") }
            .interactiveDismissDisabled(isSaving)
        }
        .onChange(of: hasStart) { _, on in draft.validFrom = on ? (draft.validFrom ?? .now) : nil }
        .onChange(of: hasExpiry) { _, on in draft.expiresAt = on ? (draft.expiresAt ?? .now.addingTimeInterval(86_400 * 365)) : nil }
    }

    private var preview: some View {
        let shown = (try? draft.makePass(now: .now)) ?? placeholder
        return PassCardView(pass: shown).padding(.vertical, Space.s)
            .accessibilityHint("Preview of your pass")
    }

    private var placeholder: WalletPass {
        WalletPass(title: draft.title.isEmpty ? String(localized: "Title") : draft.title,
                   issuer: PassIssuer(name: draft.issuer.isEmpty ? String(localized: "Issuer") : draft.issuer),
                   category: draft.category, trust: .custom, color: draft.color, createdAt: .now, updatedAt: .now)
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.m) {
                ForEach(PassColor.allCases, id: \.self) { c in
                    Button { draft.color = c } label: {
                        Circle().fill(Palette.card(c)).frame(width: 36, height: 36)
                            .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: draft.color == c ? 3 : 0).padding(-4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(c.rawValue.capitalized)
                    .accessibilityAddTraits(draft.color == c ? .isSelected : [])
                }
            }.padding(.vertical, Space.xs).padding(.horizontal, Space.xs)
        }
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, field f: DraftField, mono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            TextField(title, text: text)
                .font(mono ? .body.monospaced() : .body)
                .focused($focused, equals: f)
                .textInputAutocapitalization(mono ? .never : .words)
                .autocorrectionDisabled(mono)
                .submitLabel(.next)
            error(f)
        }
    }

    @ViewBuilder private func error(_ f: DraftField) -> some View {
        if let e = errors.first(where: { $0.field == f }) {
            Text(e.message).font(.footnote).foregroundStyle(.red).accessibilityLabel("Error: \(e.message)")
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true; defer { isSaving = false }
        switch await model.save(draft, editing: editing) {
        case .saved: dismiss()
        case .invalid(let e): errors = e; focused = e.first?.field
        case .failed: saveFailed = true
        }
    }
}
