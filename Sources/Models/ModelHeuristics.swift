import Foundation

/// モデルのメタ情報（パラメータ数・量子化・サイズ）を id / tags から推定する純粋関数群。
/// 一覧 API が実値を返さない項目を補うために使う。副作用が無くテストしやすい。
enum ModelHeuristics {

    /// "mlx-community/Llama-3.2-1B-Instruct-4bit" → "Llama-3.2-1B-Instruct-4bit"
    static func shortName(from id: String) -> String {
        id.split(separator: "/").last.map(String.init) ?? id
    }

    /// モデル名から公称パラメータ数を推定する（例: "Llama-3.2-1B" → 1_000_000_000、"...-500M" → 500_000_000）。
    static func nominalParameters(from id: String) -> Int64? {
        let name = shortName(from: id)
        // 数値+単位(B/M)。直後に英字が続く場合は除外（"4bit" の "4b" を 4B と誤読しないため）。
        let pattern = #"(\d+(?:\.\d+)?)\s*([BbMm])(?![a-zA-Z])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(name.startIndex..., in: name)
        var best: Int64?
        regex.enumerateMatches(in: name, range: range) { match, _, _ in
            guard let match,
                  let numRange = Range(match.range(at: 1), in: name),
                  let unitRange = Range(match.range(at: 2), in: name),
                  let value = Double(name[numRange]) else { return }
            let unit = name[unitRange].lowercased()
            // Double 誤差で 1.7B が 1_699_999_999 になるのを防ぐため丸める。
            let count = Int64((value * (unit == "b" ? 1_000_000_000 : 1_000_000)).rounded())
            if best == nil || count > best! { best = count }
        }
        return best
    }

    /// id / tags から量子化表記を推定する（例: "4bit" / "8bit" / "bf16"）。
    static func quantization(id: String, tags: [String]) -> String? {
        let haystack = (id + " " + tags.joined(separator: " ")).lowercased()
        for bits in ["2", "3", "4", "6", "8"] {
            if haystack.contains("\(bits)bit") || haystack.contains("\(bits)-bit") {
                return "\(bits)bit"
            }
        }
        if haystack.contains("bf16") { return "bf16" }
        if haystack.contains("fp16") || haystack.contains("float16") { return "fp16" }
        if haystack.contains("fp32") || haystack.contains("float32") { return "fp32" }
        return nil
    }

    /// パラメータ数と量子化からダウンロードサイズを概算する。
    static func estimateSize(parameters: Int64?, quantization quant: String?) -> Int64? {
        guard let parameters, parameters > 0 else { return nil }
        let bitsPerParam: Double
        switch quant {
        case "2bit": bitsPerParam = 2
        case "3bit": bitsPerParam = 3
        case "4bit": bitsPerParam = 4
        case "6bit": bitsPerParam = 6
        case "8bit": bitsPerParam = 8
        default: bitsPerParam = 16 // 既定（fp16/bf16）
        }
        let bytes = Double(parameters) * bitsPerParam / 8.0 * 1.05
        return Int64(bytes)
    }
}
