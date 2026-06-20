import Foundation

/// Preview / テスト用のモック検索サービス。ネットワークを使わずサンプルを返す。
struct MockModelService: ModelSearching {
    var models: [ModelDescriptor] = MockModelService.samples

    func search(query: String, sort: SortOption, limit: Int) async throws -> [ModelDescriptor] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = q.isEmpty
            ? models
            : models.filter { $0.displayName.lowercased().contains(q) }
        return Array(filtered.prefix(limit))
    }

    static let samples: [ModelDescriptor] = [
        ModelDescriptor(id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
                        displayName: "Hoge",
                        modality: .language, approxSizeBytes: 700_000_000,
                        parameterCount: 1_000_000_000, quantization: "4bit",
                        createdAt: nil, summary: "text-generation ・ ⬇︎ 62,327 ・ ♥ 30"),
        ModelDescriptor(id: "mlx-community/Qwen2.5-14B-Instruct-4bit",
                        displayName: "Fuga",
                        modality: .language, approxSizeBytes: 7_350_000_000,
                        parameterCount: 14_000_000_000, quantization: "4bit",
                        createdAt: nil, summary: "text-generation ・ ⬇︎ 145,726 ・ ♥ 11"),
        ModelDescriptor(id: "mlx-community/Qwen2-VL-2B-Instruct-4bit",
                        displayName: "Qwen2-VL-2B-Instruct-4bit",
                        modality: .vision, approxSizeBytes: 1_500_000_000,
                        parameterCount: 2_000_000_000, quantization: "4bit",
                        createdAt: nil, summary: "image-text-to-text ・ ⬇︎ 3,402 ・ ♥ 9"),
        ModelDescriptor(id: "mlx-community/whisper-base-mlx",
                        displayName: "whisper-base-mlx",
                        modality: .audio, approxSizeBytes: 150_000_000,
                        parameterCount: nil, quantization: nil,
                        createdAt: nil, summary: "automatic-speech-recognition ・ ⬇︎ 1,200"),
    ]
}
