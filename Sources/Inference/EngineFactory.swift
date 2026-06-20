import Foundation

/// モダリティに応じて適切なエンジン実装を生成する。
enum EngineFactory {
    static func makeEngine(for descriptor: ModelDescriptor) -> InferenceEngine {
        switch descriptor.modality {
        case .language: LanguageEngine(descriptor: descriptor)
        case .vision: VisionEngine(descriptor: descriptor)
        case .audio: AudioEngine(descriptor: descriptor)
        }
    }
}
