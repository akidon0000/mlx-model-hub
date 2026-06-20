import SwiftUI

/// モダリティごとにモデルを並べ、選択（=DL/ロード）できる一覧。
struct ModelListView: View {
    @Environment(ModelStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                if store.foundationModelsAvailable {
                    Section("OS 同梱（ダウンロード不要）") {
                        Label("Apple Foundation Model", systemImage: "apple.logo")
                            .badge("利用可能")
                    }
                }

                ForEach(Modality.allCases) { modality in
                    Section(modality.displayName) {
                        ForEach(ModelCatalog.models(for: modality)) { model in
                            ModelRow(model: model)
                        }
                    }
                }
            }
            .navigationTitle("モデル")
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
            Text(model.approxSizeText)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            statusControl(state)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !state.isBusy else { return }
            Task { await store.select(model) }
        }
    }

    @ViewBuilder
    private func statusControl(_ state: DownloadState) -> some View {
        switch state {
        case .notDownloaded:
            Label("タップでダウンロード", systemImage: "arrow.down.circle")
                .font(.caption).foregroundStyle(.blue)
        case let .downloading(progress):
            ProgressView(value: progress) {
                Text("ダウンロード中 \(Int(progress * 100))%").font(.caption2)
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
