import SwiftUI

struct ModelListView: View {
    @Environment(ModelStore.self) private var store
    @State private var searchText = ""
    @State private var selectedTab: Modality = .language

    var body: some View {
        @Bindable var store = store
        
        NavigationStack {
            List {
                modelListContent
            }
            .safeAreaInset(edge: .top) {
                Picker("ジャンル", selection: $selectedTab) {
                    ForEach(Modality.allCases) { modality in
                        Text(modality.genreLabel).tag(modality)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("モデル")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Hugging Face で MLX モデルを検索"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("並び替え", selection: $store.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Label(option.label, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("並び替え", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .onAppear { store.refreshInstalledStates() }
            .refreshable { store.refreshInstalledStates() }
            // 入力 or 並び替えが変わるたびにデバウンスして検索（空なら一覧）。
            .task(id: "\(searchText)|\(store.sortOption.rawValue)") {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                await store.search(query: searchText)
            }
        }
    }

    @ViewBuilder
    private var modelListContent: some View {
        // ダウンロード済みは検索状態に関係なく、永続化済みの一覧から常に最上部へ。
        let installed = store.downloadedModels(for: selectedTab)
        let installedIDs = Set(installed.map(\.id))

        return Group {
            if !installed.isEmpty {
                Section("ダウンロード済み") {
                    ForEach(installed) { model in
                        ModelRow(model: model)
                    }
                }
            }

            // 検索結果（同ジャンル、ダウンロード済みを除く）。
            if store.isSearching && store.searchResults.isEmpty {
                HStack { Spacer(); ProgressView("読み込み中…"); Spacer() }
            } else if let error = store.searchError {
                Label(error, systemImage: "wifi.exclamationmark")
                    .foregroundStyle(.red)
            } else {
                let results = store.searchResults
                    .filter { $0.modality == selectedTab && !installedIDs.contains($0.id) }
                if results.isEmpty {
                    if installed.isEmpty {
                        Text("該当するモデルが見つかりませんでした。")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section(selectedTab.genreLabel) {
                        ForEach(results) { model in
                            ModelRow(model: model)
                        }
                    }
                }
            }
        }
    }

    private func isInstalled(_ state: DownloadState) -> Bool {
        switch state {
        case .downloaded, .loaded: true
        default: false
        }
    }
}

#Preview {
    ModelListView()
        .environment(ModelStore.preview(activeModality: .language))
}
