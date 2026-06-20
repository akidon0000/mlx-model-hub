import Foundation
import MLXLMCommon
import Hub

/// Hugging Face Hub がモデルを保存するローカル場所を扱う。
///
/// mlx-swift-examples は `defaultHubApi`（downloadBase = Caches ディレクトリ）に
/// 重みを展開する。ここでは同じ API で保存先を求め、判定のズレを防ぐ。
enum LocalModelStorage {
    /// mlx の `defaultHubApi` と同じく Caches ディレクトリを保存先にする HubApi。
    private static var hub: HubApi {
        HubApi(downloadBase: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
    }

    /// 指定 repo のローカル保存ディレクトリ（mlx と同一ロジック）。
    static func location(for repo: String) -> URL {
        ModelConfiguration(id: repo).modelDirectory(hub: hub)
    }

    /// すでにダウンロード済みか（重みファイルが揃っているか）を判定する。
    /// config.json と少なくとも 1 つの重みファイルがあれば「済み」とみなす。
    static func isDownloaded(repo: String) -> Bool {
        let dir = location(for: repo)
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir.appendingPathComponent("config.json").path) else {
            return false
        }
        guard let files = try? fm.contentsOfDirectory(atPath: dir.path) else {
            return false
        }
        let weightSuffixes = [".safetensors", ".gguf", ".npz", ".mlx"]
        return files.contains { name in
            weightSuffixes.contains { name.hasSuffix($0) }
        }
    }

    /// ダウンロード済みの重みをローカルから削除する（アンインストール）。
    static func remove(repo: String) throws {
        let dir = location(for: repo)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
}
