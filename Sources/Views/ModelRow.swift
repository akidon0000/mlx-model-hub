import SwiftUI

/// モデル一覧の 1 行。状態に応じて DL / ロード / 進捗 / 削除などを表示する。
struct ModelRow: View {
    @Environment(ModelStore.self) private var store
    @Environment(\.openURL) private var openURL
    let model: ModelDescriptor
    @State private var showDownloadConfirm = false

    /// Hugging Face のモデルページ。
    private var webURL: URL? {
        URL(string: "https://huggingface.co/\(model.huggingFaceRepo)")
    }

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
                if let webURL {
                    Button {
                        openURL(webURL)
                    } label: {
                        Image(systemName: "safari")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.tint)
                }
                if isInstalled(state) {
                    Button {
                        store.uninstall(model)
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
            Text(model.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            let metrics = [model.parameterText, model.quantization, model.approxSizeText, model.createdAtText]
                .compactMap { $0 }
            if !metrics.isEmpty {
                Text(metrics.joined(separator: " ・ "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(model.recommendedMemoryText)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if model.isLargeForMobile {
                Label("モバイルでは起動できない可能性があります", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            statusControl(state)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            // 行タップはダウンロード済みモデルのロードのみ。DL開始は専用ボタンで。
            if case .downloaded = state { store.startLoading(model) }
        }
        .alert("ダウンロード", isPresented: $showDownloadConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("ダウンロード") { store.startLoading(model) }
        } message: {
            let size = model.approxSizeText.map { "（\($0)）" } ?? ""
            let warning = model.isLargeForMobile
                ? "\n\n⚠️ モバイルでは起動できない可能性があります。"
                : ""
            Text("\(model.displayName) のダウンロードを開始しますか？\(size)\(warning)")
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
            Button {
                showDownloadConfirm = true
            } label: {
                Label("ダウンロード", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.blue)
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
            Label("ダウンロード済み", systemImage: "internaldrive")
                .font(.caption).foregroundStyle(.secondary)
        case .loaded:
            Label("ロード済み・推論可能", systemImage: "bolt.fill")
                .font(.caption).foregroundStyle(.green)
        case let .failed(message):
            Button {
                showDownloadConfirm = true
            } label: {
                Label("\(message)（タップで再試行）", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
        }
    }
}

#Preview {
    List {
        ModelRow(model: ModelDescriptor(
            id: "mlx-community/Qwen2.5-14B-Instruct-4bit",
            displayName: "Qwen2.5-14B-Instruct-4bit",
            modality: .language, approxSizeBytes: 7_350_000_000,
            parameterCount: 14_000_000_000, quantization: "4bit",
            createdAt: nil, summary: "text-generation ・ ⬇︎ 145,726 ・ ♥ 11"))
    }
    .environment(ModelStore.preview())
}
