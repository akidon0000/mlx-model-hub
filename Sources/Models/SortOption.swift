import Foundation

/// モデル一覧の並び替え条件。
enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case downloads      // ダウンロード数（多い順）
    case likes          // いいね数（多い順）
    case createdAt      // リリース日（新しい順）
    case lastModified   // 更新日（新しい順）
    case name           // 名前（A→Z）

    var id: String { rawValue }

    var label: String {
        switch self {
        case .downloads: "ダウンロード数"
        case .likes: "いいね数"
        case .createdAt: "リリース日"
        case .lastModified: "更新日"
        case .name: "名前"
        }
    }

    var systemImage: String {
        switch self {
        case .downloads: "arrow.down.circle"
        case .likes: "heart"
        case .createdAt: "sparkles"
        case .lastModified: "clock"
        case .name: "textformat"
        }
    }

    /// Hugging Face API の sort キー。名前順はサーバ側に無いのでクライアントで処理。
    var apiKey: String? {
        switch self {
        case .downloads: "downloads"
        case .likes: "likes"
        case .createdAt: "createdAt"
        case .lastModified: "lastModified"
        case .name: nil
        }
    }
}
