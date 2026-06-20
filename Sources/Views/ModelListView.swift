import SwiftUI

/// モデルを並べ、選択（=DL/ロード）できる画面。
/// 検索欄が空のときはおすすめ（同梱カタログ）、入力すると Hugging Face を検索する。
struct ModelListView: View {
    @Environment(ModelStore.self) private var store
    @State private var searchText = ""

    var body: some View {
        @Bindable var store = store
        return NavigationStack {
            List {
                if store.foundationModelsAvailable {
                    Section("OS 同梱（ダウンロード不要）") {
                        Label("Apple Foundation Model", systemImage: "apple.logo")
                            .badge("利用可能")
                    }
                }
                modelListContent
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
        if store.isSearching && store.searchResults.isEmpty {
            HStack { Spacer(); ProgressView("読み込み中…"); Spacer() }
        } else if let error = store.searchError {
            Label(error, systemImage: "wifi.exclamationmark")
                .foregroundStyle(.red)
        } else if store.searchResults.isEmpty {
            Text("該当するモデルが見つかりませんでした。")
                .foregroundStyle(.secondary)
        } else {
            // ダウンロード済みを最上部にまとめる。
            let installed = store.searchResults.filter { isInstalled(store.state(for: $0)) }
            if !installed.isEmpty {
                Section("ダウンロード済み") {
                    ForEach(installed) { model in
                        ModelRow(model: model)
                    }
                }
            }

            // 残りをジャンル（LLM / VLM / Voice）ごとにセクション分け。
            let remaining = store.searchResults.filter { !isInstalled(store.state(for: $0)) }
            ForEach(Modality.allCases) { modality in
                let models = remaining.filter { $0.modality == modality }
                if !models.isEmpty {
                    Section(modality.genreLabel) {
                        ForEach(models) { model in
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

private struct ModelRow: View {
    @Environment(ModelStore.self) private var store
    let model: ModelDescriptor

    var body: some View {
        let state = store.state(for: model)
        let isActive = store.activeDescriptor?.id == model.id

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: model.modality.systemImage)
                    .foregroundStyle(.tint)
                Text(model.displayName).font(.headline)
                Spacer()
                if isActive { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            }
            Text(model.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            let metrics = [model.parameterText, model.approxSizeText, model.createdAtText]
                .compactMap { $0 }
            if !metrics.isEmpty {
                Text(metrics.joined(separator: " ・ "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            statusControl(state)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !state.isBusy else { return }
            store.startLoading(model)
        }
        .swipeActions(edge: .trailing) {
            if isInstalled(state) {
                Button(role: .destructive) {
                    store.uninstall(model)
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
    }

    /// ローカルに重みがある（=アンインストール可能）状態か。
    private func isInstalled(_ state: DownloadState) -> Bool {
        switch state {
        case .downloaded, .loaded: true
        default: false
        }
    }

    @ViewBuilder
    private func statusControl(_ state: DownloadState) -> some View {
        switch state {
        case .notDownloaded:
            Label("タップでダウンロード", systemImage: "arrow.down.circle")
                .font(.caption).foregroundStyle(.blue)
        case let .downloading(progress):
            HStack {
                ProgressView(value: progress) {
                    Text("ダウンロード中 \(Int(progress * 100))%").font(.caption2)
                }
                Button {
                    store.cancelLoading(model)
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }
        case .downloaded:
            Label("ダウンロード済み（タップでロード）", systemImage: "internaldrive")
                .font(.caption).foregroundStyle(.secondary)
        case .loaded:
            Label("ロード済み・推論可能", systemImage: "bolt.fill")
                .font(.caption).foregroundStyle(.green)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.caption).foregroundStyle(.red)
        }
    }
}
