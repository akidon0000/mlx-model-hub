import SwiftUI

@main
struct MLXModelHubApp: App {
    /// アプリ全体で共有するモデル管理ストア。
    /// カタログ・ダウンロード状態・選択中モデルを保持する。
    @State private var store = ModelStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
