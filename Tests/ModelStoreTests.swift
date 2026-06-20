import Testing
@testable import MLXModelHub

@Suite("ModelStore（モック検索）")
@MainActor
struct ModelStoreTests {

    @Test("モック検索で結果が入る")
    func search() async {
        let store = ModelStore(service: MockModelService())
        await store.search(query: "")
        #expect(!store.searchResults.isEmpty)
        #expect(store.searchError == nil)
    }

    @Test("クエリで絞り込まれる")
    func searchFiltered() async {
        let store = ModelStore(service: MockModelService())
        await store.search(query: "Qwen2-VL")
        #expect(store.searchResults.allSatisfy { $0.displayName.localizedCaseInsensitiveContains("Qwen2-VL") })
    }

    @Test("ダウンロード済み判定は状態に基づく")
    func downloadedModels() async {
        let store = ModelStore.preview(activeModality: .language)
        // preview は language の 1 件をロード済みにしている。
        #expect(!store.downloadedModels(for: .language).isEmpty)
        #expect(store.downloadedModels(for: .audio).isEmpty)
    }
}

@Suite("ModelDescriptor 表示")
struct ModelDescriptorTests {

    @Test("3GB 超は isLargeForMobile = true")
    func largeForMobile() {
        let big = ModelDescriptor(id: "x", displayName: "x", modality: .language,
                                  approxSizeBytes: 7_000_000_000, summary: "")
        let small = ModelDescriptor(id: "y", displayName: "y", modality: .language,
                                    approxSizeBytes: 700_000_000, summary: "")
        #expect(big.isLargeForMobile)
        #expect(!small.isLargeForMobile)
    }

    @Test("パラメータ表記")
    func parameterText() {
        var d = ModelDescriptor(id: "x", displayName: "x", modality: .language,
                                approxSizeBytes: nil, summary: "")
        d.parameterCount = 1_000_000_000
        #expect(d.parameterText == "1.0B params")
        d.parameterCount = 500_000_000
        #expect(d.parameterText == "500M params")
    }
}
