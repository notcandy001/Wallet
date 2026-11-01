import SwiftUI

struct WalletHomeView: View {
    @Environment(WalletModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [UUID] = []
    @State private var showingAdd = false
    @State private var showingSettings = false

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $path) {
            content
                .background(Palette.background)
                .navigationTitle(Brand.name)
                .navigationDestination(for: UUID.self) { id in
                    PassDetailView(passID: id)
                }
                .searchable(text: $model.query.text, prompt: "Search passes")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showingSettings = true } label: { Label("Settings", systemImage: "gearshape") }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        sortMenu
                        Button { showingAdd = true } label: { Label("Add pass", systemImage: "plus") }
                    }
                }
                .sheet(isPresented: $showingAdd) { AddEditPassView(editing: nil) }
                .sheet(isPresented: $showingSettings) { SettingsView() }
                .alert("Notice", isPresented: noticeBinding) {
                    Button("OK", role: .cancel) { model.notice = nil }
                } message: { Text(model.notice ?? "") }
        }
    }

    private var noticeBinding: Binding<Bool> {
        Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })
    }

    @ViewBuilder private var content: some View {
        switch model.loadState {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView("Can't open Wallet", systemImage: "exclamationmark.triangle", description: Text(message))
        case .ready:
            let passes = model.visiblePasses
            ScrollView {
                LazyVStack(spacing: Space.m, pinnedViews: []) {
                    categoryChips
                    if passes.isEmpty { emptyState } else {
                        ForEach(passes) { pass in
                            NavigationLink(value: pass.id) { PassCardView(pass: pass, now: model.now) }
                                .buttonStyle(PressableCardStyle())
                                .accessibilityHint("Opens pass details")
                        }
                    }
                }
                .padding(.horizontal, Space.m).padding(.bottom, Space.xl)
                .animation(Motion.animation(Motion.spring, reduceMotion: reduceMotion), value: passes.map(\.id))
            }
        }
    }

    private var categoryChips: some View {
        @Bindable var model = model
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s) {
                chip("All", selected: model.query.category == nil) { model.query.category = nil }
                ForEach(PassCategory.allCases, id: \.self) { c in
                    chip(c.plainTitle, selected: model.query.category == c) { model.query.category = c }
                }
            }
            .padding(.vertical, Space.xs)
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.medium))
                .padding(.horizontal, Space.m).padding(.vertical, Space.s)
                .background(selected ? Color.accentColor : Palette.surface, in: Capsule())
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var sortMenu: some View {
        @Bindable var model = model
        return Menu {
            Picker("Sort", selection: $model.query.sort) {
                Text("Recently added").tag(PassQuery.Sort.recentlyAdded)
                Text("Title").tag(PassQuery.Sort.title)
                Text("Expiry").tag(PassQuery.Sort.expiry)
            }
            Picker("Show", selection: $model.query.scope) {
                Text("Active").tag(PassQuery.Scope.active)
                Text("Archived (\(model.archivedCount))").tag(PassQuery.Scope.archived)
            }
        } label: { Label("Sort and filter", systemImage: "line.3.horizontal.decrease.circle") }
    }

    @ViewBuilder private var emptyState: some View {
        if model.query.isFiltering {
            ContentUnavailableView {
                Label("No matching passes", systemImage: "magnifyingglass")
            } description: { Text("Try a different search or category.") } actions: {
                Button("Clear filters") { model.query.clearFilters() }
            }
        } else if model.query.scope == .archived {
            ContentUnavailableView("No archived passes", systemImage: "archivebox",
                                   description: Text("Passes you archive appear here."))
        } else {
            ContentUnavailableView {
                Label("Your wallet is empty", systemImage: "wallet.pass")
            } description: { Text("Add a pass to get started.") } actions: {
                Button("Add pass") { showingAdd = true }.buttonStyle(.borderedProminent)
            }
        }
    }
}

struct PressableCardStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
