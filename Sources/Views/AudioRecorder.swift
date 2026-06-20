import Foundation
import AVFoundation
import Observation

/// マイクから録音し、書き起こし対象の音声ファイル URL を生成する。
@MainActor
@Observable
final class AudioRecorder {
    private(set) var isRecording = false
    private(set) var lastRecordingURL: URL?

    private var recorder: AVAudioRecorder?

    /// マイク許可を求めてから録音を開始する。
    func start() async throws {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            throw EngineError.unsupported("マイクへのアクセスが許可されていません。")
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        // ASR が扱いやすい 16kHz モノラル WAV。
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        self.recorder = recorder
        lastRecordingURL = url
        isRecording = true
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
