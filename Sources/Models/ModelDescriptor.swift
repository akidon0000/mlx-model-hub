import Foundation

/// カタログ上の 1 モデルを表す記述子。
/// Hugging Face の repo id を起点に、アプリ内ダウンロードの単位になる。
struct ModelDescriptor: Identifiable, Hashable, Sendable, Codable {
    /// Hugging Face Hub の repo id（例: "mlx-community/Llama-3.2-1B-Instruct-4bit"）。
    /// そのまま一意な識別子として使う。
    let id: String
    let displayName: String
    let modality: Modality
    /// 量子化後のおおよそのダウンロードサイズ（表示用）。検索結果では不明なこともある。
    let approxSizeBytes: Int64?
    /// パラメータ総数（safetensors の total）。不明なこともある。
    var parameterCount: Int64? = nil
    /// リリース日（HF の createdAt）。不明なこともある。
    var createdAt: Date? = nil
    let summary: String

    var huggingFaceRepo: String { id }

    var approxSizeText: String? {
        guard let approxSizeBytes else { return nil }
        return "約 " + ByteCountFormatter.string(fromByteCount: approxSizeBytes, countStyle: .file)
    }

    /// "1.2B" / "350M" のような人間向けパラメータ数表記。
    var parameterText: String? {
        guard let count = parameterCount else { return nil }
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        if Double(count) >= billion {
            return String(format: "%.1fB params", Double(count) / billion)
        } else if Double(count) >= million {
            return String(format: "%.0fM params", Double(count) / million)
        }
        return "\(count) params"
    }

    var createdAtText: String? {
        guard let createdAt else { return nil }
        return createdAt.formatted(.dateTime.year().month().day())
    }
}
