import Foundation

/// 各モデルのダウンロード/ロードの状態。UI はこれを見て表示を切り替える。
enum DownloadState: Equatable, Sendable {
    case notDownloaded
    case downloading(progress: Double)   // 0.0 ... 1.0
    case downloaded                       // ローカルに重みが揃っている
    case loaded                           // メモリ上に展開され推論可能
    case failed(message: String)

    var isBusy: Bool {
        if case .downloading = self { return true }
        return false
    }

    var progress: Double? {
        if case let .downloading(p) = self { return p }
        return nil
    }
}
