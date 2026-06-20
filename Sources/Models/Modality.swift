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

    /// セクション見出し用のジャンル表記。
    var genreLabel: String {
        switch self {
        case .language: "LLM"
        case .vision: "VLM"
        case .audio: "Voice"
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
        // "vl" の部分一致は "vllm" 等で誤判定するため、限定的なキーワードに絞る。
        if matches(["image-text-to-text", "image-to-text", "visual-question-answering",
                    "image-classification", "vision", "multimodal", "-vl-",
                    "llava", "qwen2-vl", "qwen2.5-vl", "internvl", "minicpm-v",
                    "smolvlm", "idefics", "pixtral", "paligemma"]) {
            return .vision
        }
        return .language
    }
}
