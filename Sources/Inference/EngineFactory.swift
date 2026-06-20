import Foundation

/// モダリティに応じて適切なエンジン実装を生成する。
enum EngineFactory {
    static func makeEngine(for descriptor: ModelDescriptor) -> InferenceEngine {
        if descriptor.id == ModelDescriptor.foundationModelsID {
            return FoundationModelsEngine(descriptor: descriptor)
        }
        switch descriptor.modality {
        case .language: return LanguageEngine(descriptor: descriptor)
        case .vision: return VisionEngine(descriptor: descriptor)
        case .audio: return AudioEngine(descriptor: descriptor)
        }
    }
}
