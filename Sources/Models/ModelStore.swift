import Foundation
import Observation

/// アプリ全体の状態の中心。
/// - カタログの提示
/// - 各モデルのダウンロード/ロード状態の管理
/// - 「選択中（=推論に使う）」モデルの保持と切り替え
@MainActor
@Observable
final class ModelStore {
    let catalog: [ModelDescriptor] = ModelCatalog.all

    /// repo id -> 状態
    private(set) var states: [String: DownloadState] = [:]

    /// 現在ロード済みで推論に使えるエンジン（モデル切替時に入れ替え）。
    private(set) var activeEngine: InferenceEngine?
    private(set) var activeDescriptor: ModelDescriptor?

    /// FoundationModels（OS 同梱）が使えるか。
    let foundationModelsAvailable = FoundationModelsEngine.isAvailable

    func state(for descriptor: ModelDescriptor) -> DownloadState {
        states[descriptor.id] ?? .notDownloaded
    }

    /// モデルを選択 → 必要ならダウンロード/ロードして active にする。
    func select(_ descriptor: ModelDescriptor) async {
        // 既存の active を解放してメモリを空ける。
        if let current = activeDescriptor, current.id != descriptor.id {
            await activeEngine?.unload()
            states[current.id] = .downloaded
        }

        states[descriptor.id] = .downloading(progress: 0)
        let engine = EngineFactory.makeEngine(for: descriptor)
        do {
            try await engine.load { [weak self] progress in
                Task { @MainActor in
                    self?.states[descriptor.id] = .downloading(progress: progress)
                }
            }
            activeEngine = engine
            activeDescriptor = descriptor
            states[descriptor.id] = .loaded
        } catch {
            states[descriptor.id] = .failed(message: error.localizedDescription)
        }
    }

    /// 現在の言語/映像エンジンでテキスト生成。
    func generate(prompt: String, images: [Data] = []) -> AsyncThrowingStream<String, Error> {
        guard let engine = activeEngine as? TextGenerating else {
            return AsyncThrowingStream { $0.finish(throwing: EngineError.notLoaded) }
        }
        return engine.generate(prompt: prompt, images: images)
    }
}
