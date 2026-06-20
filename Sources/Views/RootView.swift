import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ModelListView()
                .tabItem { Label("モデル", systemImage: "square.stack.3d.up") }

            ChatView()
                .tabItem { Label("チャット", systemImage: "text.bubble") }
        }
    }
}
