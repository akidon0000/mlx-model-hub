import SwiftUI

/// 選択中モデルと対話するチャット画面（LINE 風吹き出し UI）。
struct ChatView: View {
    @Environment(ModelStore.self) private var store
    @State private var input = ""
    @State private var messages: [ChatMessage] = []
    @State private var isGenerating = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modelStatus
                    .padding(.horizontal)
                    .padding(.top, 8)

                conversation

                inputBar
            }
            .background(Color(.systemGroupedBackground))
            .contentShape(Rectangle())
            .onTapGesture { isInputFocused = false }
            .navigationTitle("チャット")
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var modelStatus: some View {
        ActiveModelMenu(modality: .language)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if messages.isEmpty {
                        Text("メッセージを送ると、ここに会話が表示されます")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                    ForEach(messages) { message in
                        ChatBubble(message: message).id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.last?.text) { _, _ in
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("メッセージを入力", text: $input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .lineLimit(1...5)
            Button {
                Task { await send() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .padding(8)
                    .background(canSend ? Color.accentColor : Color.gray.opacity(0.4), in: .circle)
                    .foregroundStyle(.white)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isGenerating
            && store.activeDescriptor != nil
    }

    private func send() async {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        isInputFocused = false
        input = ""

        messages.append(ChatMessage(role: .user, text: prompt))
        var assistant = ChatMessage(role: .assistant, text: "")
        messages.append(assistant)
        let assistantId = assistant.id

        isGenerating = true
        defer { isGenerating = false }
        do {
            for try await chunk in store.generate(prompt: prompt) {
                assistant.text += chunk
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx] = assistant
                }
            }
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                messages[idx].text = "エラー: \(error.localizedDescription)"
            }
        }
    }
}

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text.isEmpty && message.role == .assistant ? "…" : message.text)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(bubbleColor, in: .rect(cornerRadius: 16))
                .foregroundStyle(textColor)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var bubbleColor: Color {
        message.role == .user ? Color(red: 0.35, green: 0.78, blue: 0.35) : Color(.secondarySystemBackground)
    }
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
}

#Preview {
    ChatView()
        .environment(ModelStore.preview(activeModality: .language))
}
