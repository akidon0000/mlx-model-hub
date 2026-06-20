import Foundation

/// モデル検索の抽象。実通信(HFModelService)とモック(MockModelService)を差し替えられる。
protocol ModelSearching: Sendable {
    func search(query: String, sort: SortOption, limit: Int) async throws -> [ModelDescriptor]
}

/// Hugging Face Hub の検索 API を叩いて、MLX 対応モデルを動的に取得する。
///
/// エンドポイント: https://huggingface.co/api/models
/// `mlx-community` 製作者で絞り込み、ダウンロード数順に返す。
struct HFModelService: ModelSearching {

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
    func search(query: String, sort: SortOption = .downloads, limit: Int = 200) async throws -> [ModelDescriptor] {
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
            let params = ModelHeuristics.nominalParameters(from: model.id) ?? model.safetensors?.total
            let quant = ModelHeuristics.quantization(id: model.id, tags: tags)
            return ModelDescriptor(
                id: model.id,
                displayName: ModelHeuristics.shortName(from: model.id),
                modality: modality,
                approxSizeBytes: ModelHeuristics.estimateSize(parameters: params, quantization: quant),
                parameterCount: params,
                quantization: quant,
                createdAt: model.createdAt.flatMap { isoFormatter.date(from: $0) },
                summary: summary(downloads: model.downloads, likes: model.likes, tag: model.pipeline_tag)
            )
        }

        // モバイル実行不可なサイズは一覧から除外。
        // 推定不能（nil/0）のものは判定保留として残す。
        let filtered = descriptors.filter { d in
            guard let size = d.approxSizeBytes, size > 0 else { return true }
            return size <= ModelDescriptor.mobileSizeLimitBytes
        }

        // 名前順だけサーバが対応しないのでクライアントで並べ替える。
        if sort == .name {
            return filtered.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        }
        return filtered
    }

    private func summary(downloads: Int?, likes: Int?, tag: String?) -> String {
        var parts: [String] = []
        if let tag { parts.append(tag) }
        if let downloads { parts.append("⬇︎ \(downloads.formatted())") }
        if let likes { parts.append("♥ \(likes.formatted())") }
        return parts.joined(separator: " ・ ")
    }
}
