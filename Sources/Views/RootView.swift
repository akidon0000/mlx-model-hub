import SwiftUI

struct RootView: View {
    @Environment(ModelStore.self) private var store

    var body: some View {
        TabView {
            ChatView()
                .tabItem { Label("チャット", systemImage: "text.bubble") }

            CameraView()
                .tabItem { Label("カメラ", systemImage: "camera") }

            AudioView()
                .tabItem { Label("音声", systemImage: "waveform") }

            ModelListView()
                .tabItem { Label("モデル", systemImage: "square.stack.3d.up") }
        }
        .task { await store.autoLoadIfNeeded() }
    }
}
