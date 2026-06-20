import Foundation

/// 音声書き起こしエンジン（Whisper など）。
///
/// MLX 版 Whisper は mlx-swift-examples のコア外（別パッケージ / 自前移植）になることが多い。
/// まずはインターフェースだけ確定させ、実装は後続で差し込む。
/// 候補:
///   - https://github.com/argmaxinc/WhisperKit （Core ML ベース、すぐ使える）
///   - MLX 版 whisper の Swift 移植
final class AudioEngine: Transcribing, @unchecked Sendable {
    let descriptor: ModelDescriptor
    private var isLoaded = false

    init(descriptor: ModelDescriptor) {
        self.descriptor = descriptor
    }

    func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        // TODO: WhisperKit もしくは MLX whisper のロードに置き換える。
        progress(1.0)
        isLoaded = true
    }

    func unload() async {
        isLoaded = false
    }

    func transcribe(audio url: URL) async throws -> String {
        guard isLoaded else { throw EngineError.notLoaded }
        throw EngineError.unsupported("音声書き起こしは未実装です。WhisperKit を統合してください。")
    }
}
