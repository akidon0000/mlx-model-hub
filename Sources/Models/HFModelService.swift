import Foundation

/// Hugging Face Hub の検索 API を叩いて、MLX 対応モデルを動的に取得する。
///
/// エンドポイント: https://huggingface.co/api/models
/// `mlx-community` 製作者で絞り込み、ダウンロード数順に返す。
struct HFModelService {

    /// API レスポンスの 1 件分（必要なフィールドのみ）。
    private struct APIModel: Decodable {
        let id: String
        let pipeline_tag: String?
        let tags: [String]?
        let downloads: Int?
        let likes: Int?
        let createdAt: String?    // ISO8601 のリリース日
        let safetensors: Safetensors?

        struct Safetensors: Decodable {
            let total: Int64?     // パラメータ総数
        }
    }

    enum ServiceError: LocalizedError {
        case badResponse
        var errorDescription: String? { "モデル一覧の取得に失敗しました。" }
    }

    /// キーワードでモデルを検索する。
    /// - Parameters:
    ///   - query: 検索語（空なら人気順の一覧）。
    ///   - limit: 取得件数。
    func search(query: String, sort: SortOption = .downloads, limit: Int = 40) async throws -> [ModelDescriptor] {
        var components = URLComponents(string: "https://huggingface.co/api/models")!
        // 名前順はサーバ側に無いので、その場合はダウンロード数で取得してから並べ替える。
        let apiSort = sort.apiKey ?? "downloads"
        // expand を使うと既定フィールドが省かれるため、必要な項目を明示的に要求する。
        components.queryItems = [
            URLQueryItem(name: "author", value: "mlx-community"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "sort", value: apiSort),
            URLQueryItem(name: "direction", value: "-1"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "expand[]", value: "downloads"),
            URLQueryItem(name: "expand[]", value: "likes"),
            URLQueryItem(name: "expand[]", value: "pipeline_tag"),
            URLQueryItem(name: "expand[]", value: "tags"),
            URLQueryItem(name: "expand[]", value: "createdAt"),
            URLQueryItem(name: "expand[]", value: "safetensors"),
        ]
        guard let url = components.url else { throw ServiceError.badResponse }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let models = try JSONDecoder().decode([APIModel].self, from: data)
        let isoFormatter = ISO8601DateFormatter()
        let descriptors = models.map { model -> ModelDescriptor in
            let tags = model.tags ?? []
            let modality = Modality.infer(pipelineTag: model.pipeline_tag, tags: tags)
            // 量子化モデルの safetensors.total はパック後の要素数で実態とズレるため、
            // モデル名から公称パラメータ数を優先的に推定し、無ければ safetensors を使う。
            let params = nominalParameters(from: model.id) ?? model.safetensors?.total
            return ModelDescriptor(
                id: model.id,
                displayName: shortName(from: model.id),
                modality: modality,
                approxSizeBytes: estimateSize(parameters: params, id: model.id, tags: tags),
                parameterCount: params,
                createdAt: model.createdAt.flatMap { isoFormatter.date(from: $0) },
                summary: summary(downloads: model.downloads, likes: model.likes, tag: model.pipeline_tag)
            )
        }

        // 名前順だけサーバが対応しないのでクライアントで並べ替える。
        if sort == .name {
            return descriptors.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        }
        return descriptors
    }

    /// モデル名から公称パラメータ数を推定する（例: "Llama-3.2-1B" → 1_000_000_000、"...-500M" → 500_000_000）。
    private func nominalParameters(from id: String) -> Int64? {
        let name = shortName(from: id)
        // "3.8B" / "0.5B" / "7B" / "500M" のような数値+単位を拾う。
        let pattern = #"(\d+(?:\.\d+)?)\s*([BbMm])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(name.startIndex..., in: name)
        var best: Int64?
        regex.enumerateMatches(in: name, range: range) { match, _, _ in
            guard let match,
                  let numRange = Range(match.range(at: 1), in: name),
                  let unitRange = Range(match.range(at: 2), in: name),
                  let value = Double(name[numRange]) else { return }
            let unit = name[unitRange].lowercased()
            let count = Int64(value * (unit == "b" ? 1_000_000_000 : 1_000_000))
            // 複数該当した場合は最大（"3.2-1B" の 1B 等を優先しすぎないよう最大値採用）。
            if best == nil || count > best! { best = count }
        }
        return best
    }

    /// パラメータ数と量子化ビット数からダウンロードサイズを概算する。
    /// 一覧 API は実バイト数を返さないため、id / tags から量子化を推定して見積もる。
    private func estimateSize(parameters: Int64?, id: String, tags: [String]) -> Int64? {
        guard let parameters, parameters > 0 else { return nil }
        let haystack = (id + " " + tags.joined(separator: " ")).lowercased()

        let bitsPerParam: Double
        if haystack.contains("3bit") || haystack.contains("3-bit") {
            bitsPerParam = 3
        } else if haystack.contains("4bit") || haystack.contains("4-bit") {
            bitsPerParam = 4
        } else if haystack.contains("6bit") || haystack.contains("6-bit") {
            bitsPerParam = 6
        } else if haystack.contains("8bit") || haystack.contains("8-bit") {
            bitsPerParam = 8
        } else {
            bitsPerParam = 16 // 既定（fp16/bf16）
        }
        // メタデータ等のオーバーヘッドを軽く上乗せ。
        let bytes = Double(parameters) * bitsPerParam / 8.0 * 1.05
        return Int64(bytes)
    }

    /// "mlx-community/Llama-3.2-1B-Instruct-4bit" → "Llama-3.2-1B-Instruct-4bit"
    private func shortName(from id: String) -> String {
        id.split(separator: "/").last.map(String.init) ?? id
    }

    private func summary(downloads: Int?, likes: Int?, tag: String?) -> String {
        var parts: [String] = []
        if let tag { parts.append(tag) }
        if let downloads { parts.append("⬇︎ \(downloads.formatted())") }
        if let likes { parts.append("♥ \(likes.formatted())") }
        return parts.joined(separator: " ・ ")
    }
}
