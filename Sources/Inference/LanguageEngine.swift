import Foundation
import MLXLLM
import MLXLMCommon

/// MLX の LLM を使う言語エンジン。
/// mlx-swift-examples の `LLMModelFactory` 経由でダウンロード + ロードする。
///
/// 注意: mlx-swift-examples の API は更新が速い。コンパイルが通らない場合は
/// 取得したバージョンの `MLXLMCommon.generate` / `loadContainer` シグネチャに合わせて調整する。
final class LanguageEngine: TextGenerating, @unchecked Sendable {
    let descriptor: ModelDescriptor
    private var container: ModelContainer?

    init(descriptor: ModelDescriptor) {
        self.descriptor = descriptor
    }

    func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard container == nil else { return }
        let configuration = ModelConfiguration(id: descriptor.huggingFaceRepo)
        container = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { p in
            progress(p.fractionCompleted)
        }
    }

    func unload() async {
        container = nil
    }

    func generate(prompt: String, images: [Data]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let container else {
                        throw EngineError.notLoaded
                    }
                    let userInput = UserInput(messages: [
                        ["role": "user", "content": prompt]
                    ])
                    try await container.perform { context in
                        let input = try await context.processor.prepare(input: userInput)
                        let stream = try MLXLMCommon.generate(
                            input: input,
                            parameters: GenerateParameters(temperature: 0.7),
                            context: context
                        )
                        for await item in stream {
                            if let chunk = item.chunk {
                                continuation.yield(chunk)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

enum EngineError: LocalizedError {
    case notLoaded
    case unsupported(String)

    var errorDescription: String? {
        switch self {
        case .notLoaded: "モデルがまだロードされていません。"
        case let .unsupported(msg): msg
        }
    }
}
