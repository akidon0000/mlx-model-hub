import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple 純正のオンデバイス LLM（FoundationModels, iOS 26+）を使うエンジン。
///
/// MLX モデルとは違いダウンロード不要・OS 同梱。
/// 「まず無料で即動く既定モデル」としてカタログ先頭に置ける。
/// Xcode 27 / 新 API が来たらここを更新する。
final class FoundationModelsEngine: @unchecked Sendable {

    /// 端末が FoundationModels を利用可能か。
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    func generate(prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                Task {
                    do {
                        let session = LanguageModelSession()
                        let stream = session.streamResponse(to: prompt)
                        for try await partial in stream {
                            continuation.yield(partial.content)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                return
            }
            #endif
            continuation.finish(throwing: EngineError.unsupported("この端末では FoundationModels を利用できません。"))
        }
    }
}
