import SwiftUI
import PhotosUI
import UIKit

/// 画像を撮影/選択し、VLM（映像モデル）に質問する画面。
struct CameraView: View {
    @Environment(ModelStore.self) private var store
    @State private var image: UIImage?
    @State private var prompt = "この画像には何が写っていますか？"
    @State private var output = ""
    @State private var isGenerating = false
    @State private var showCamera = false
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                modelStatus

                imageArea

                HStack {
                    if CameraPicker.isAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            Label("撮影", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("ライブラリ", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                }

                TextField("画像への質問", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await analyze() }
                } label: {
                    Label("解析", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(image == nil || prompt.isEmpty || isGenerating || !store.activeMatches(.vision))

                ScrollView {
                    Text(output.isEmpty ? "解析結果がここに表示されます" : output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(output.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("カメラ")
            .toolbar { ModelSwitcher(modality: .vision) }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image = $0 }
                    .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        image = ui
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var modelStatus: some View {
        if store.activeMatches(.vision), let active = store.activeDescriptor {
            Label("\(active.displayName) で実行中", systemImage: "bolt.fill")
                .font(.caption).foregroundStyle(.green)
        } else {
            Label("「モデル」タブで映像モデルを選択してください", systemImage: "info.circle")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var imageArea: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .clipShape(.rect(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
                .frame(height: 200)
                .overlay {
                    Label("画像を撮影 / 選択", systemImage: "photo.badge.plus")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func analyze() async {
        guard let image, let data = image.jpegData(compressionQuality: 0.9) else { return }
        output = ""
        isGenerating = true
        defer { isGenerating = false }
        do {
            for try await chunk in store.generate(prompt: prompt, images: [data]) {
                output += chunk
            }
        } catch {
            output = "エラー: \(error.localizedDescription)"
        }
    }
}

#Preview {
    CameraView()
        .environment(ModelStore.preview(activeModality: .vision))
}
