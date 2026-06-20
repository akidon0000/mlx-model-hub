import SwiftUI

/// 「〜で実行中」表示をそのままタップして、同じモダリティのダウンロード済みモデルを
/// 切り替えられるトグル。モデル未選択時はガイド文を表示する。
struct ActiveModelMenu: View {
    @Environment(ModelStore.self) private var store
    let modality: Modality

    var body: some View {
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
            label(modelsAvailable: !models.isEmpty)
        }
        .disabled(models.isEmpty && store.activeDescriptor == nil)
    }

    @ViewBuilder
    private func label(modelsAvailable: Bool) -> some View {
        if store.activeMatches(modality), let active = store.activeDescriptor {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text("\(active.displayName) で実行中")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .font(.caption)
            .foregroundStyle(.green)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                Text(modelsAvailable
                     ? "タップして\(modality.genreLabel)を選択"
                     : "「モデル」タブで\(modality.genreLabel)を選択してください")
                if modelsAvailable {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
