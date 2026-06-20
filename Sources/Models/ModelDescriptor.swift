import Foundation

/// カタログ上の 1 モデルを表す記述子。
/// Hugging Face の repo id を起点に、アプリ内ダウンロードの単位になる。
struct ModelDescriptor: Identifiable, Hashable, Sendable {
    /// Hugging Face Hub の repo id（例: "mlx-community/Llama-3.2-1B-Instruct-4bit"）。
    /// そのまま一意な識別子として使う。
    let id: String
    let displayName: String
    let modality: Modality
    /// 量子化後のおおよそのダウンロードサイズ（表示用）。
    let approxSizeBytes: Int64
    let summary: String

    var huggingFaceRepo: String { id }

    var approxSizeText: String {
        ByteCountFormatter.string(fromByteCount: approxSizeBytes, countStyle: .file)
    }
}
