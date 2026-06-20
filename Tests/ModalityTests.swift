import Testing
@testable import MLXModelHub

@Suite("Modality.infer")
struct ModalityTests {

    @Test("音声系タグを audio と判定")
    func audio() {
        #expect(Modality.infer(pipelineTag: "automatic-speech-recognition", tags: []) == .audio)
        #expect(Modality.infer(pipelineTag: nil, tags: ["whisper"]) == .audio)
    }

    @Test("画像系タグを vision と判定")
    func vision() {
        #expect(Modality.infer(pipelineTag: "image-text-to-text", tags: []) == .vision)
        #expect(Modality.infer(pipelineTag: nil, tags: ["qwen2-vl"]) == .vision)
    }

    @Test("既定は language")
    func language() {
        #expect(Modality.infer(pipelineTag: "text-generation", tags: []) == .language)
    }

    @Test("vllm タグで vision に誤判定しない")
    func vllmNotVision() {
        #expect(Modality.infer(pipelineTag: "text-generation", tags: ["vllm"]) == .language)
    }
}
