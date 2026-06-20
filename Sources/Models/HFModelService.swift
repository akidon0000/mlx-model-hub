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
    }

    enum ServiceError: LocalizedError {
        case badResponse
        var errorDescription: String? { "モデル一覧の取得に失敗しました。" }
    }

    /// キーワードでモデルを検索する。
    /// - Parameters:
    ///   - query: 検索語（空なら人気順の一覧）。
    ///   - limit: 取得件数。
    func search(query: String, limit: Int = 40) async throws -> [ModelDescriptor] {
        var components = URLComponents(string: "https://huggingface.co/api/models")!
        components.queryItems = [
            URLQueryItem(name: "author", value: "mlx-community"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "sort", value: "downloads"),
            URLQueryItem(name: "direction", value: "-1"),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        guard let url = components.url else { throw ServiceError.badResponse }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let models = try JSONDecoder().decode([APIModel].self, from: data)
        return models.map { model in
            let tags = model.tags ?? []
            let modality = Modality.infer(pipelineTag: model.pipeline_tag, tags: tags)
            return ModelDescriptor(
                id: model.id,
                displayName: shortName(from: model.id),
                modality: modality,
                approxSizeBytes: nil, // 一覧 API ではサイズ不明（DL 時に取得される）
                summary: summary(downloads: model.downloads, likes: model.likes, tag: model.pipeline_tag)
            )
        }
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
