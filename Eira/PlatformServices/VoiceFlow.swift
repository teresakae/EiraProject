import Foundation
import AVFoundation
import Observation

@MainActor @Observable
final class VoiceFlow {
    private let client: any ServerClient
    private var recorder: AVAudioRecorder?
    private var audioURL: URL?
    private var operation: Task<Void, Never>?
    private var generation = UUID()
    private(set) var isRecording = false
    private(set) var isWorking = false
    var errorMessage: String?

    init(client: any ServerClient) { self.client = client }

    func start() {
        guard !isRecording, !isWorking else { return }
        errorMessage = nil
        let token = generation
        isWorking = true
        operation = Task {
            let permitted = await AVAudioApplication.requestRecordPermission()
            guard token == generation, !Task.isCancelled else { return }
            isWorking = false
            guard permitted else { errorMessage = "Allow microphone access in Settings to record audio."; return }
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .default)
                try session.setActive(true)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("eira-\(UUID()).m4a")
                audioURL = url
                let recording = try AVAudioRecorder(url: url, settings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44_100,
                    AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ])
                recorder = recording
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
                guard recording.record() else { throw CocoaError(.fileWriteUnknown) }
                isRecording = true
            } catch {
                cancel()
                errorMessage = "Recording could not start. You can still type."
            }
        }
    }

    func finish(into write: WriteFlow) {
        finish { transcript in
            // Preserve anything she already typed; she reviews the result before sending.
            write.text += (write.text.isEmpty ? "" : "\n") + transcript
            write.source = .voice
        }
    }

    func finish(onTranscript: @escaping (String) -> Void) {
        guard isRecording, let url = audioURL else { return }
        recorder?.stop()
        recorder = nil
        isRecording = false
        isWorking = true
        let token = generation
        operation = Task {
            defer { if token == generation { isWorking = false } }
            do {
                let transcript = try await transcribeFile(url)
                guard token == generation, !Task.isCancelled else { return }
                onTranscript(transcript)
            } catch {
                if token == generation, !Task.isCancelled {
                    errorMessage = "Audio could not be transcribed. You can record again or type."
                }
            }
        }
    }

    func transcribeFile(_ url: URL) async throws -> String {
        audioURL = url
        defer { try? AVAudioSession.sharedInstance().setActive(false) }
        do {
            let audio = try Data(contentsOf: url)
            guard !audio.isEmpty, audio.count <= 4_000_000 else { throw CocoaError(.fileReadTooLarge) }
            let transcript = try await client.transcribe(.init(audio: audio, filename: url.lastPathComponent, contentType: "audio/mp4"))
            try removeAudio(url)
            try Task.checkCancellation()
            return transcript
        } catch {
            try removeAudio(url)
            throw error
        }
    }

    private func removeAudio(_ url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        if audioURL == url { audioURL = nil }
    }

    func cancel() {
        generation = UUID()
        operation?.cancel()
        operation = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        isWorking = false
        errorMessage = nil
        if let audioURL {
            do { try removeAudio(audioURL) }
            catch { errorMessage = "The audio file could not be deleted. Try again." }
        }
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
