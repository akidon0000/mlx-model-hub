import SwiftUI

/// 音声を録音し、ASR（音声モデル）で文字起こしする画面。
struct AudioView: View {
    @Environment(ModelStore.self) private var store
    @State private var recorder = AudioRecorder()
    @State private var transcript = ""
    @State private var isTranscribing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                modelStatus

                Button {
                    Task { await toggleRecording() }
                } label: {
                    Label(
                        recorder.isRecording ? "録音停止" : "録音開始",
                        systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(recorder.isRecording ? .red : .accentColor)

                if isTranscribing {
                    ProgressView("文字起こし中…")
                }

                ScrollView {
                    Text(transcript.isEmpty ? "書き起こし結果がここに表示されます" : transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(transcript.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("音声")
        }
    }

    @ViewBuilder
    private var modelStatus: some View {
        if store.activeMatches(.audio), let active = store.activeDescriptor {
            Label("\(active.displayName) で実行中", systemImage: "bolt.fill")
                .font(.caption).foregroundStyle(.green)
        } else {
            Label("「モデル」タブで音声モデルを選択してください", systemImage: "info.circle")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func toggleRecording() async {
        if recorder.isRecording {
            recorder.stop()
            await transcribe()
        } else {
            do {
                try await recorder.start()
            } catch {
                transcript = "エラー: \(error.localizedDescription)"
            }
        }
    }

    private func transcribe() async {
        guard let url = recorder.lastRecordingURL else { return }
        isTranscribing = true
        defer { isTranscribing = false }
        do {
            transcript = try await store.transcribe(audio: url)
        } catch {
            transcript = "エラー: \(error.localizedDescription)"
        }
    }
}
