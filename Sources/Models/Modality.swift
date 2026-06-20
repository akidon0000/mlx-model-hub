import Foundation

/// モデルが扱うモダリティ。言語・音声・映像（マルチモーダル）を区別する。
enum Modality: String, CaseIterable, Identifiable, Codable, Sendable {
    case language   // テキスト生成（LLM）
    case vision     // 画像 + テキスト（VLM）
    case audio      // 音声認識 / 音声生成

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .language: "言語"
        case .vision: "映像"
        case .audio: "音声"
        }
    }

    var systemImage: String {
        switch self {
        case .language: "text.bubble"
        case .vision: "photo"
        case .audio: "waveform"
        }
    }
}
