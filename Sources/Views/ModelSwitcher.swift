import SwiftUI

/// 各画面（チャット/カメラ/音声）でダウンロード済みモデルを切り替えるツールバーメニュー。
/// 指定モダリティのインストール済みモデルだけを候補に出す。
struct ModelSwitcher: ToolbarContent {
    @Environment(ModelStore.self) private var store
    let modality: Modality

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            let models = store.downloadedModels(for: modality)
            Menu {
                if models.isEmpty {
                    Text("ダウンロード済みの\(modality.genreLabel)がありません")
                } else {
                    ForEach(models) { model in
                        Button {
                            store.startLoading(model)
                        } label: {
                            if store.activeDescriptor?.id == model.id {
                                Label(model.displayName, systemImage: "checkmark")
                            } else {
                                Text(model.displayName)
                            }
                        }
                    }
                }
            } label: {
                Label("モデル切替", systemImage: "arrow.left.arrow.right.circle")
            }
            .disabled(models.isEmpty)
        }
    }
}
