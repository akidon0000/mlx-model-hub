import Testing
@testable import MLXModelHub

@Suite("ModelHeuristics")
struct ModelHeuristicsTests {

    @Test("repo id から表示名を取り出す")
    func shortName() {
        #expect(ModelHeuristics.shortName(from: "mlx-community/Llama-3.2-1B-Instruct-4bit")
                == "Llama-3.2-1B-Instruct-4bit")
        #expect(ModelHeuristics.shortName(from: "noslash") == "noslash")
    }

    @Test("モデル名から公称パラメータ数を推定する", arguments: [
        ("mlx-community/Llama-3.2-1B-Instruct-4bit", Int64(1_000_000_000)),
        ("mlx-community/Qwen2.5-14B-Instruct-4bit", Int64(14_000_000_000)),
        ("mlx-community/SmolLM2-1.7B-Instruct", Int64(1_700_000_000)),
        ("mlx-community/some-500M-model", Int64(500_000_000)),
    ])
    func nominalParameters(id: String, expected: Int64) {
        #expect(ModelHeuristics.nominalParameters(from: id) == expected)
    }

    @Test("パラメータ表記が無ければ nil")
    func nominalParametersNil() {
        #expect(ModelHeuristics.nominalParameters(from: "mlx-community/whisper-base") == nil)
    }

    @Test("量子化を推定する", arguments: [
        ("mlx-community/Llama-3.2-1B-Instruct-4bit", "4bit"),
        ("mlx-community/model-8bit", "8bit"),
        ("mlx-community/model-bf16", "bf16"),
        ("mlx-community/plain", nil),
    ] as [(String, String?)])
    func quantization(id: String, expected: String?) {
        #expect(ModelHeuristics.quantization(id: id, tags: []) == expected)
    }

    @Test("4bit 1B モデルのサイズ概算は ~525MB")
    func estimateSize4bit() {
        let bytes = ModelHeuristics.estimateSize(parameters: 1_000_000_000, quantization: "4bit")
        // 1e9 * 4 / 8 * 1.05 = 525,000,000
        #expect(bytes == 525_000_000)
    }

    @Test("パラメータ不明ならサイズも nil")
    func estimateSizeNil() {
        #expect(ModelHeuristics.estimateSize(parameters: nil, quantization: "4bit") == nil)
    }
}
