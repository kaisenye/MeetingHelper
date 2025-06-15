import Foundation
import AVFoundation
import Combine

class AudioCaptureService: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var error: AudioCaptureError?
    
    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    // MARK: - Public Methods
    
    func requestPermission() async -> Bool {
        // On macOS, we need to request microphone permission
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    func startRecording(to url: URL) throws {
        guard !isRecording else { return }
        
        recordingURL = url
        
        do {
            try setupAudioEngine(outputURL: url)
            try audioEngine.start()
            isRecording = true
            error = nil
        } catch {
            self.error = .recordingFailed(error.localizedDescription)
            throw error
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioFile = nil
        isRecording = false
        recordingURL = nil
    }
    
    func pauseRecording() {
        guard isRecording else { return }
        audioEngine.pause()
    }
    
    func resumeRecording() {
        guard !audioEngine.isRunning && isRecording else { return }
        try? audioEngine.start()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine(outputURL: URL) throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Create audio file for recording
        audioFile = try AVAudioFile(forWriting: outputURL, settings: recordingFormat.settings)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine.prepare()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Write to file
        try? audioFile?.write(from: buffer)
        
        // Calculate audio level
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0, (avgPower + 80) / 80) // Normalize to 0-1 range
        
        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
        }
    }
}

// MARK: - System Audio Capture Extension
extension AudioCaptureService {
    // Note: System audio capture on macOS requires special permissions
    // and may need to use ScreenCaptureKit for macOS 12.3+
    func startSystemAudioCapture() throws {
        // This would require ScreenCaptureKit implementation
        // For now, we'll use microphone input
        throw AudioCaptureError.systemAudioNotSupported
    }
}

// MARK: - Error Types
enum AudioCaptureError: LocalizedError {
    case permissionDenied
    case recordingFailed(String)
    case systemAudioNotSupported
    case audioEngineError(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .systemAudioNotSupported:
            return "System audio capture not supported"
        case .audioEngineError(let message):
            return "Audio engine error: \(message)"
        }
    }
} 