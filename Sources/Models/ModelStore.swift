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

    /// インストール済みモデルの記述子（id -> descriptor）。
    /// 検索しなくても各画面で切り替えられるよう永続化する。
    private(set) var installedModels: [String: ModelDescriptor] = [:]
    private let installedKey = "installedModels"

    /// 現在ロード済みで推論に使えるエンジン（モデル切替時に入れ替え）。
    private(set) var activeEngine: InferenceEngine?
    private(set) var activeDescriptor: ModelDescriptor?

    /// FoundationModels（OS 同梱）が使えるか。
    let foundationModelsAvailable = FoundationModelsEngine.isAvailable

    // MARK: - Hugging Face 検索
    private let hfService: ModelSearching
    private(set) var searchResults: [ModelDescriptor] = []
    private(set) var isSearching = false
    private(set) var searchError: String?
    /// 現在の並び替え条件。
    var sortOption: SortOption = .downloads

    /// 最後に選択（=ロード）したモデル id。自動ロードの優先対象にする。
    private let lastSelectedKey = "lastSelectedModelID"
    private var lastSelectedID: String? {
        get { UserDefaults.standard.string(forKey: lastSelectedKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastSelectedKey) }
    }

    init(service: ModelSearching = HFModelService()) {
        self.hfService = service
        loadInstalledModels()
        refreshInstalledStates()
    }

    // MARK: - インストール済みモデルの永続化

    private func loadInstalledModels() {
        guard let data = UserDefaults.standard.data(forKey: installedKey),
              let decoded = try? JSONDecoder().decode([String: ModelDescriptor].self, from: data)
        else { return }
        installedModels = decoded
    }

    private func persistInstalledModels() {
        if let data = try? JSONEncoder().encode(installedModels) {
            UserDefaults.standard.set(data, forKey: installedKey)
        }
    }

    /// インストール済みとして記録する。
    private func recordInstalled(_ descriptor: ModelDescriptor) {
        installedModels[descriptor.id] = descriptor
        persistInstalledModels()
    }

    /// 指定モダリティのダウンロード済みモデル一覧（切り替え候補）。
    /// 判定は状態（downloaded / loaded）に基づく。
    func downloadedModels(for modality: Modality) -> [ModelDescriptor] {
        installedModels.values
            .filter { $0.modality == modality }
            .filter { $0.id != ModelDescriptor.foundationModelsID } // FM は別経路で表示
            .filter {
                switch states[$0.id] {
                case .downloaded, .loaded: true
                default: false
                }
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func state(for descriptor: ModelDescriptor) -> DownloadState {
        states[descriptor.id] ?? .notDownloaded
    }

    /// ローカルキャッシュを走査し、すでに重みが揃っているモデルを
    /// `.downloaded` として反映する。起動時とダウンロード完了後に呼ぶ。
    /// ロード中/ロード済みのモデルの状態は維持する。
    func refreshInstalledStates() {
        // カタログ + これまでにインストール記録したモデルを対象に走査。
        let known = catalog + installedModels.values.filter { d in
            !catalog.contains { $0.id == d.id }
        }
        for descriptor in known {
            if case .loaded = states[descriptor.id] { continue }
            if states[descriptor.id]?.isBusy == true { continue }
            if LocalModelStorage.isDownloaded(repo: descriptor.huggingFaceRepo) {
                states[descriptor.id] = .downloaded
                recordInstalled(descriptor)
            } else if installedModels[descriptor.id] != nil {
                // 記録はあるが実体が消えている → 記録も整理。
                installedModels[descriptor.id] = nil
                persistInstalledModels()
            }
        }
    }

    /// active モデルが無ければ、ダウンロード済みモデルを自動でロードする。
    /// 優先順位: 最後に選んだモデル → カタログ順で最初のダウンロード済みモデル。
    func autoLoadIfNeeded() async {
        guard activeEngine == nil else { return }
        // すでにロード処理中（DL中）なら二重起動しない。
        guard !states.values.contains(where: { $0.isBusy }) else { return }

        let downloaded = catalog.filter {
            LocalModelStorage.isDownloaded(repo: $0.huggingFaceRepo)
        }
        guard !downloaded.isEmpty else { return }

        let target = downloaded.first { $0.id == lastSelectedID } ?? downloaded[0]
        await select(target)
    }

    /// 指定モダリティに対して active モデルが無ければ、その種別の
    /// ダウンロード済みモデルを自動でロードする。各タブ表示時に呼ぶ。
    func autoLoadIfNeeded(for modality: Modality) async {
        if let active = activeDescriptor, active.modality == modality { return }
        guard !states.values.contains(where: { $0.isBusy }) else { return }

        let candidates = downloadedModels(for: modality)
        let target = candidates.first { $0.id == lastSelectedID } ?? candidates.first
        guard let target else { return }
        await select(target)
    }

    /// 進行中のダウンロード/ロード Task（停止用に保持）。
    private var loadTasks: [String: Task<Void, Never>] = [:]

    /// モデルの選択（DL/ロード）を開始する。停止できるよう Task で包む。
    func startLoading(_ descriptor: ModelDescriptor) {
        guard loadTasks[descriptor.id] == nil else { return }
        let task = Task { [weak self] in
            await self?.select(descriptor)
            self?.loadTasks[descriptor.id] = nil
        }
        loadTasks[descriptor.id] = task
    }

    /// 進行中のダウンロードを停止する。
    func cancelLoading(_ descriptor: ModelDescriptor) {
        loadTasks[descriptor.id]?.cancel()
        loadTasks[descriptor.id] = nil
        // 途中まで取得済みなら downloaded、無ければ notDownloaded に戻す。
        states[descriptor.id] = LocalModelStorage.isDownloaded(repo: descriptor.huggingFaceRepo)
            ? .downloaded : .notDownloaded
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
            lastSelectedID = descriptor.id
            recordInstalled(descriptor)
        } catch is CancellationError {
            // 停止操作。cancelLoading 側で状態を整えるためここでは何もしない。
        } catch {
            if Task.isCancelled {
                return
            }
            states[descriptor.id] = .failed(message: error.localizedDescription)
        }
    }

    /// モデルをローカルから削除（アンインストール）する。
    /// active なら先に解放してから削除する。
    func uninstall(_ descriptor: ModelDescriptor) {
        if activeDescriptor?.id == descriptor.id {
            Task { await activeEngine?.unload() }
            activeEngine = nil
            activeDescriptor = nil
        }
        do {
            try LocalModelStorage.remove(repo: descriptor.huggingFaceRepo)
            states[descriptor.id] = .notDownloaded
            installedModels[descriptor.id] = nil
            persistInstalledModels()
        } catch {
            states[descriptor.id] = .failed(message: "削除に失敗: \(error.localizedDescription)")
        }
    }

    /// Hugging Face Hub を検索して結果を保持する。
    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            let results = try await hfService.search(query: trimmed, sort: sortOption, limit: 200)
            // 取得直後にローカルの DL 済み状態を反映。
            for model in results where states[model.id] == nil {
                if LocalModelStorage.isDownloaded(repo: model.huggingFaceRepo) {
                    states[model.id] = .downloaded
                    recordInstalled(model)
                }
            }
            searchResults = results
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }
    }

    func clearSearch() {
        searchResults = []
        searchError = nil
    }

    /// 現在の言語/映像エンジンでテキスト生成。
    func generate(prompt: String, images: [Data] = []) -> AsyncThrowingStream<String, Error> {
        guard let engine = activeEngine as? TextGenerating else {
            return AsyncThrowingStream { $0.finish(throwing: EngineError.notLoaded) }
        }
        return engine.generate(prompt: prompt, images: images)
    }

    /// 現在の音声エンジンで書き起こし。
    func transcribe(audio url: URL) async throws -> String {
        guard let engine = activeEngine as? Transcribing else {
            throw EngineError.unsupported("音声モデルを選択してください（「モデル」タブの音声）。")
        }
        return try await engine.transcribe(audio: url)
    }

    /// 現在の active モデルが指定モダリティかどうか。
    func activeMatches(_ modality: Modality) -> Bool {
        activeDescriptor?.modality == modality
    }
}

#if DEBUG
extension ModelStore {
    /// SwiftUI Preview / テスト用のサンプル状態を持つストア（ネットワーク不使用）。
    static func preview(activeModality: Modality? = nil) -> ModelStore {
        let store = ModelStore(service: MockModelService())
        let samples = MockModelService.samples
        store.searchResults = samples
        if let modality = activeModality,
           let sample = samples.first(where: { $0.modality == modality }) {
            store.activeDescriptor = sample
            store.states[sample.id] = .loaded
            store.installedModels[sample.id] = sample
        }
        return store
    }
}
#endif
