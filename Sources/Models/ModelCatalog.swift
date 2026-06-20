import Foundation

/// アプリに同梱する「選択可能なモデル」の一覧。
/// ここに追記するだけで UI のモデルリストに並び、ダウンロード対象になる。
///
/// すべて `mlx-community` の MLX 変換済みモデルを指す。
/// repo id は Hugging Face 上の実在するものに合わせて適宜更新すること。
enum ModelCatalog {
    static let all: [ModelDescriptor] = language + vision + audio

    static let language: [ModelDescriptor] = [
        ModelDescriptor(
            id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            displayName: "Llama 3.2 1B Instruct (4bit)",
            modality: .language,
            approxSizeBytes: 700_000_000,
            summary: "軽量で iPhone でも動かしやすい汎用チャットモデル。"
        ),
        ModelDescriptor(
            id: "mlx-community/Qwen2.5-3B-Instruct-4bit",
            displayName: "Qwen2.5 3B Instruct (4bit)",
            modality: .language,
            approxSizeBytes: 1_900_000_000,
            summary: "日本語にも強いバランス型。iPad / 高メモリ端末向け。"
        ),
    ]

    static let vision: [ModelDescriptor] = [
        ModelDescriptor(
            id: "mlx-community/Qwen2-VL-2B-Instruct-4bit",
            displayName: "Qwen2-VL 2B (4bit)",
            modality: .vision,
            approxSizeBytes: 1_500_000_000,
            summary: "画像を入力してテキストで説明・質問応答できる VLM。"
        ),
    ]

    static let audio: [ModelDescriptor] = [
        ModelDescriptor(
            id: "mlx-community/whisper-base-mlx",
            displayName: "Whisper base",
            modality: .audio,
            approxSizeBytes: 150_000_000,
            summary: "音声をテキストに書き起こす ASR モデル。"
        ),
    ]

    static func models(for modality: Modality) -> [ModelDescriptor] {
        all.filter { $0.modality == modality }
    }
}
