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

    /// Hugging Face の pipeline_tag / tags からモダリティを推定する。
    /// 判別できない場合は言語(LLM)として扱う。
    static func infer(pipelineTag: String?, tags: [String]) -> Modality {
        let haystack = ([pipelineTag] + tags)
            .compactMap { $0?.lowercased() }

        func matches(_ keywords: [String]) -> Bool {
            haystack.contains { tag in keywords.contains { tag.contains($0) } }
        }

        if matches(["automatic-speech-recognition", "text-to-speech",
                    "text-to-audio", "audio", "speech", "whisper"]) {
            return .audio
        }
        if matches(["image-text-to-text", "image-to-text", "visual-question-answering",
                    "vision", "multimodal", "-vl-", "vl", "llava", "qwen2-vl"]) {
            return .vision
        }
        return .language
    }
}
