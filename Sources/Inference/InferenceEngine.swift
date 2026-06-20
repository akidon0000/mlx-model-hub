import Foundation

/// 1 モデルの「ロード済みインスタンス」を抽象化するプロトコル。
/// 言語・映像・音声の各エンジンがこれに準拠し、ModelStore から統一的に扱える。
protocol InferenceEngine: AnyObject, Sendable {
    var descriptor: ModelDescriptor { get }

    /// 重みをメモリへ展開する。`progress` は 0.0...1.0。
    /// ローカルに未取得なら Hugging Face からのダウンロードもここで行われる。
    func load(progress: @escaping @Sendable (Double) -> Void) async throws

    /// メモリを解放する（別モデルへ切り替える前に呼ぶ）。
    func unload() async
}

/// テキスト入出力で逐次トークンを返せるエンジン（言語・映像が準拠）。
protocol TextGenerating: InferenceEngine {
    /// プロンプトを与え、生成テキストを少しずつ流す AsyncStream を返す。
    func generate(prompt: String, images: [Data]) -> AsyncThrowingStream<String, Error>
}

/// 音声書き起こしエンジン。
protocol Transcribing: InferenceEngine {
    func transcribe(audio url: URL) async throws -> String
}
