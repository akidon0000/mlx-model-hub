import SwiftUI
import UIKit

/// カメラタブ。タブ表示時にカメラ UI を起動し、シャッターを押すと
/// VLM 解析結果がモーダルで返ってくる。
struct CameraView: View {
    @Environment(ModelStore.self) private var store
    @State private var prompt = "この画像には何が写っていますか？"
    @State private var showCamera = false

    @State private var resultImage: UIImage?
    @State private var resultOutput = ""
    @State private var isGenerating = false
    @State private var showResult = false

    private var canCapture: Bool {
        store.activeMatches(.vision) && !isGenerating
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ActiveModelMenu(modality: .vision)

                TextField("画像への質問", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Spacer()

                if !CameraPicker.isAvailable {
                    Label("このデバイスではカメラが利用できません", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                } else if !store.activeMatches(.vision) {
                    Text("映像モデルを選択するとカメラを起動します")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        showCamera = true
                    } label: {
                        Label("カメラを起動", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCapture)

                    Text("シャッターを押すと自動で解析が始まります")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("カメラ")
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { ui in
                    MemoryLog.log("camera.captured", "size=\(Int(ui.size.width))x\(Int(ui.size.height)) scale=\(ui.scale)")
                    handleCaptured(ui)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showResult) {
                ResultSheet(
                    image: resultImage,
                    output: resultOutput,
                    isGenerating: isGenerating
                )
            }
            .onAppear {
                MemoryLog.log("camera.view.appear")
                autoLaunchCamera()
            }
            .task { await store.autoLoadIfNeeded(for: .vision) }
        }
    }

    private func autoLaunchCamera() {
        guard CameraPicker.isAvailable,
              canCapture,
              !showCamera,
              !showResult else { return }
        showCamera = true
    }

    private func handleCaptured(_ image: UIImage) {
        resultImage = image
        resultOutput = ""
        showResult = true
        Task { await analyze(image: image) }
    }

    private func analyze(image: UIImage) async {
        MemoryLog.log("analyze.start", "src=\(Int(image.size.width))x\(Int(image.size.height))")
        let resized = image.resizedForVLM(maxDimension: 1024)
        MemoryLog.log("analyze.resized", "dst=\(Int(resized.size.width))x\(Int(resized.size.height))")
        guard let data = resized.jpegData(compressionQuality: 0.9) else { return }
        MemoryLog.log("analyze.jpeg", "bytes=\(data.count)")
        isGenerating = true
        defer {
            isGenerating = false
            MemoryLog.log("analyze.end")
        }
        do {
            var chunks = 0
            for try await chunk in store.generate(prompt: prompt, images: [data]) {
                resultOutput += chunk
                chunks += 1
                if chunks % 16 == 0 { MemoryLog.log("analyze.streaming", "chunks=\(chunks)") }
            }
        } catch {
            resultOutput = "エラー: \(error.localizedDescription)"
            MemoryLog.log("analyze.error", error.localizedDescription)
        }
    }
}

private struct ResultSheet: View {
    let image: UIImage?
    let output: String
    let isGenerating: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    if isGenerating && output.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("解析中…")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(output)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("解析結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .disabled(isGenerating)
                }
            }
        }
    }
}

#Preview {
    CameraView()
        .environment(ModelStore.preview(activeModality: .vision))
}
