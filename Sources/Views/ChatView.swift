import SwiftUI

/// 選択中モデルと対話する最小チャット画面。
struct ChatView: View {
    @Environment(ModelStore.self) private var store
    @State private var input = ""
    @State private var output = ""
    @State private var isGenerating = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if let active = store.activeDescriptor {
                    Label("\(active.displayName) で実行中", systemImage: "bolt.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    Label("「モデル」タブでモデルを選択してください", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }

                ScrollView {
                    Text(output.isEmpty ? "ここに生成結果が表示されます" : output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(output.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 12))

                HStack {
                    TextField("メッセージを入力", text: $input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(input.isEmpty || isGenerating || store.activeDescriptor == nil)
                }
            }
            .padding()
            .contentShape(Rectangle())   // 余白部分もタップ判定に含める
            .onTapGesture { isInputFocused = false }
            .navigationTitle("チャット")
            .scrollDismissesKeyboard(.interactively)
            .toolbar { ModelSwitcher(modality: .language) }
        }
    }

    private func send() async {
        isInputFocused = false
        let prompt = input
        input = ""
        output = ""
        isGenerating = true
        defer { isGenerating = false }
        do {
            for try await chunk in store.generate(prompt: prompt) {
                output += chunk
            }
        } catch {
            output = "エラー: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ChatView()
        .environment(ModelStore.preview(activeModality: .language))
}
