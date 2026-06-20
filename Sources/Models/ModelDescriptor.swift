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
    /// 量子化表記（例: "4bit" / "8bit" / "bf16"）。不明なこともある。
    var quantization: String? = nil
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

    /// モバイルで快適に動かせる目安の上限（3GB）。これを超えると警告対象。
    static let mobileSizeLimitBytes: Int64 = 3_000_000_000

    /// Apple Foundation Models（OS 同梱）を表す合成記述子。
    /// HF からのダウンロード不要で、id はローカル固定。
    static let foundationModelsID = "apple.foundation"
    static let foundationModels = ModelDescriptor(
        id: foundationModelsID,
        displayName: "Apple Foundation Model",
        modality: .language,
        approxSizeBytes: nil,
        parameterCount: nil,
        quantization: nil,
        createdAt: nil,
        summary: "OS 同梱・ダウンロード不要"
    )

    /// サイズが大きく、モバイルでの動作に注意が必要か。
    var isLargeForMobile: Bool {
        guard let approxSizeBytes else { return false }
        return approxSizeBytes > Self.mobileSizeLimitBytes
    }

    /// 推定推奨メモリ。重みサイズ + KV キャッシュ/中間バッファぶん（おおよそ +1GB）。
    /// HF API は推奨メモリを公開していないため重みサイズからの概算であることに注意。
    var recommendedMemoryBytes: Int64? {
        guard let size = approxSizeBytes, size > 0 else { return nil }
        return size + 1_000_000_000
    }

    /// "推奨メモリ: 約 X GB" の表示。算出できなければ "不明" を返す。
    var recommendedMemoryText: String {
        guard let bytes = recommendedMemoryBytes else { return "推奨メモリ: 不明" }
        return "推奨メモリ: 約 " + ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory)
    }
}
