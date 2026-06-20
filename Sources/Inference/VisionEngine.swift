import Foundation
import MLXVLM
import MLXLMCommon

/// MLX の VLM（画像 + テキスト）を使う映像エンジン。
final class VisionEngine: TextGenerating, @unchecked Sendable {
    let descriptor: ModelDescriptor
    private var container: ModelContainer?

    init(descriptor: ModelDescriptor) {
        self.descriptor = descriptor
    }

    func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard container == nil else { return }
        let configuration = ModelConfiguration(id: descriptor.huggingFaceRepo)
        container = try await VLMModelFactory.shared.loadContainer(
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
                    guard let container else { throw EngineError.notLoaded }
                    let userInput = UserInput(
                        messages: [["role": "user", "content": prompt]],
                        images: images.map { .ciImage(.init(data: $0) ?? .init()) }
                    )
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
