import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: NSObject, ObservableObject {
    @Published var isTranscribing = false
    @Published var currentTranscript = ""
    @Published var transcriptSegments: [TranscriptSegment] = []
    @Published var error: SpeechRecognitionError?
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Segment management
    private var currentSegmentText = ""
    private var segmentStartTime = Date()
    private var segmentTimer: Timer?
    private let segmentTimeout: TimeInterval = 3.0 // 3 seconds of silence creates new segment
    
    init(locale: String = "en-US") {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        super.init()
        speechRecognizer?.delegate = self
    }
    
    // MARK: - Public Methods
    
    func requestPermission() async -> Bool {
        let speechStatus = await requestSpeechRecognitionPermission()
        let audioStatus = await requestAudioPermission()
        return speechStatus && audioStatus
    }
    
    func startTranscription() {
        guard !isTranscribing else { 
            print("Transcription already in progress")
            return 
        }
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = .recognizerUnavailable
            return
        }
        
        // Ensure we start from a clean state
        stopTranscription()
        
        do {
            try startRecognition()
            isTranscribing = true
            error = nil
        } catch {
            self.error = .recognitionFailed(error.localizedDescription)
            isTranscribing = false
        }
    }
    
    func stopTranscription() {
        guard isTranscribing else { return }
        
        // Stop audio engine safely
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove tap safely (this won't crash if no tap exists)
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Clean up recognition components
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        // Clean up timers
        segmentTimer?.invalidate()
        segmentTimer = nil
        
        // Finalize current segment if it has content
        if !currentSegmentText.isEmpty {
            finalizeCurrentSegment()
        }
        
        isTranscribing = false
    }
    
    func processAudioData(_ data: Data) {
        // This method can be used to process audio data from external sources
        // For now, we're using the audio engine's input directly
    }
    
    func clearTranscript() {
        currentTranscript = ""
        transcriptSegments.removeAll()
        currentSegmentText = ""
    }
    
    func exportTranscript() -> String {
        return transcriptSegments.map { segment in
            let timestamp = DateFormatter.timestamp.string(from: segment.timestamp)
            let speaker = segment.speaker ?? "Unknown"
            return "[\(timestamp)] \(speaker): \(segment.text)"
        }.joined(separator: "\n")
    }
    
    // MARK: - Private Methods
    
    private func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func requestAudioPermission() async -> Bool {
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
    
    private func startRecognition() throws {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Stop audio engine and remove any existing taps
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.handleRecognitionResult(result, error: error)
        }
        
        // Reset segment tracking
        segmentStartTime = Date()
        startSegmentTimer()
    }
    
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = .recognitionFailed(error.localizedDescription)
            }
            return
        }
        
        guard let result = result else { return }
        
        let transcribedText = result.bestTranscription.formattedString
        
        DispatchQueue.main.async {
            self.currentTranscript = transcribedText
            self.currentSegmentText = transcribedText
            
            // Reset segment timer on new speech
            self.resetSegmentTimer()
            
            if result.isFinal {
                self.finalizeCurrentSegment()
            }
        }
    }
    
    private func startSegmentTimer() {
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentTimeout, repeats: false) { [weak self] _ in
            self?.finalizeCurrentSegment()
        }
    }
    
    private func resetSegmentTimer() {
        segmentTimer?.invalidate()
        startSegmentTimer()
    }
    
    private func finalizeCurrentSegment() {
        guard !currentSegmentText.isEmpty else { return }
        
        let segment = TranscriptSegment(
            text: currentSegmentText,
            confidence: 0.8, // Default confidence
            duration: Date().timeIntervalSince(segmentStartTime),
            speaker: nil // Speaker identification would require additional implementation
        )
        
        transcriptSegments.append(segment)
        
        // Reset for next segment
        currentSegmentText = ""
        segmentStartTime = Date()
        
        // Instead of restarting recognition, just continue with the current session
        // The recognition will continue naturally without needing to restart
        if isTranscribing {
            startSegmentTimer()
        }
    }
    
    private func restartRecognition() throws {
        // Stop current recognition cleanly
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Stop audio engine and remove tap
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Clear references
        recognitionRequest = nil
        recognitionTask = nil
        
        // Small delay before restarting to ensure cleanup is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard self.isTranscribing else { return }
            do {
                try self.startRecognition()
            } catch {
                self.error = .recognitionFailed(error.localizedDescription)
                self.isTranscribing = false
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func changeLanguage(to locale: String) {
        // This would require reinitializing the speech recognizer
        // For now, we'll just note that it's not implemented
        print("Language change to \(locale) not implemented")
    }
    
    static func supportedLocales() -> [String] {
        return SFSpeechRecognizer.supportedLocales().map { $0.identifier }
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.error = .recognizerUnavailable
            }
        }
    }
}

// MARK: - Error Types
enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case requestCreationFailed
    case recognitionFailed(String)
    case audioEngineError(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .recognizerUnavailable:
            return "Speech recognizer unavailable"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .audioEngineError(let message):
            return "Audio engine error: \(message)"
        }
    }
} 