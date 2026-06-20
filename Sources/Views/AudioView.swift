import SwiftUI

/// マイクボタン長押し中だけ録音→離すと文字起こしが走る画面。
struct AudioView: View {
    @Environment(ModelStore.self) private var store
    @State private var recorder = AudioRecorder()
    @State private var transcript = ""
    @State private var isTranscribing = false
    @State private var isPressing = false

    private var canRecord: Bool {
        store.activeMatches(.audio) && !isTranscribing
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                modelStatus

                ScrollView {
                    Text(transcript.isEmpty ? "ボタンを長押ししている間だけ録音し、離すと文字起こしされます" : transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(transcript.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 12))

                Spacer()

                statusText

                micButton
                    .padding(.bottom, 24)
            }
            .padding()
            .navigationTitle("音声")
        }
    }

    private var modelStatus: some View {
        ActiveModelMenu(modality: .audio)
    }

    @ViewBuilder
    private var statusText: some View {
        if isTranscribing {
            HStack(spacing: 8) {
                ProgressView()
                Text("文字起こし中…").foregroundStyle(.secondary)
            }
        } else if recorder.isRecording {
            Label("録音中", systemImage: "waveform")
                .foregroundStyle(.red)
        } else {
            Text("長押しで録音").foregroundStyle(.secondary)
        }
    }

    private var micButton: some View {
        ZStack {
            Circle()
                .fill(recorder.isRecording ? Color.red : Color.accentColor)
                .frame(width: 96, height: 96)
                .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                .opacity(canRecord ? 1.0 : 0.4)
                .animation(.easeInOut(duration: 0.15), value: recorder.isRecording)

            Image(systemName: "mic.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
        .contentShape(Circle())
        .onLongPressGesture(
            minimumDuration: 60,
            maximumDistance: .infinity,
            perform: { },
            onPressingChanged: { pressing in
                guard canRecord else { return }
                if pressing {
                    startRecording()
                } else {
                    stopAndTranscribe()
                }
            }
        )
        .disabled(!canRecord)
    }

    private func startRecording() {
        guard !recorder.isRecording else { return }
        transcript = ""
        Task {
            do {
                try await recorder.start()
            } catch {
                transcript = "エラー: \(error.localizedDescription)"
            }
        }
    }

    private func stopAndTranscribe() {
        guard recorder.isRecording else { return }
        recorder.stop()
        Task { await transcribe() }
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

#Preview {
    AudioView()
        .environment(ModelStore.preview(activeModality: .audio))
}
