import Foundation
import Combine
import SwiftUI

@MainActor
class MeetingManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentMeeting: Meeting?
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var currentTranscript = ""
    @Published var audioLevel: Float = 0.0
    @Published var error: MeetingManagerError?
    @Published var recordingDuration: TimeInterval = 0
    
    // MARK: - Services
    private let audioService = AudioCaptureService()
    private let speechService = SpeechRecognitionService()
    private let fileService = FileManagerService()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var lastTranscriptSave = Date()
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind audio service properties
        audioService.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        audioService.$audioLevel
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
        
        audioService.$error
            .compactMap { $0 }
            .map { MeetingManagerError.audioError($0.localizedDescription) }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        // Bind speech service properties
        speechService.$isTranscribing
            .assign(to: \.isTranscribing, on: self)
            .store(in: &cancellables)
        
        speechService.$currentTranscript
            .assign(to: \.currentTranscript, on: self)
            .store(in: &cancellables)
        
        speechService.$error
            .compactMap { $0 }
            .map { MeetingManagerError.speechError($0.localizedDescription) }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        // Handle new transcript segments
        speechService.$transcriptSegments
            .sink { [weak self] segments in
                self?.handleNewTranscriptSegment(segments)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Meeting Control
    func startMeeting(title: String, audioSource: AudioSource = .microphone, participants: [String] = []) async {
        do {
            // Request permissions
            let audioPermission = await audioService.requestPermission()
            let speechPermission = await speechService.requestPermission()
            
            guard audioPermission && speechPermission else {
                error = .permissionDenied
                return
            }
            
            // Create new meeting
            let meeting = Meeting(
                title: title,
                audioSource: audioSource,
                participants: participants
            )
            
            // Create audio file URL
            let audioURL = fileService.getAudioFileURL(for: meeting.id)
            
            // Start services
            try audioService.startRecording(to: audioURL)
            speechService.startTranscription()
            
            // Update state
            currentMeeting = meeting
            recordingStartTime = Date()
            startRecordingTimer()
            
            error = nil
            
        } catch {
            self.error = .startFailed(error.localizedDescription)
        }
    }
    
    func stopMeeting() async {
        guard var meeting = currentMeeting else { return }
        
        do {
            // Stop services
            audioService.stopRecording()
            speechService.stopTranscription()
            
            // Stop timer
            stopRecordingTimer()
            
            // Update meeting with end time
            meeting.endTime = Date()
            
            // Save meeting and transcript
            fileService.saveMeeting(meeting)
            
            if !speechService.transcriptSegments.isEmpty {
                let transcript = MeetingTranscript(
                    meetingId: meeting.id,
                    segments: speechService.transcriptSegments,
                    createdAt: Date(),
                    lastUpdated: Date()
                )
                fileService.saveTranscript(transcript)
                meeting.transcriptPath = fileService.getTranscriptsDirectoryURL().appendingPathComponent("\(meeting.id.uuidString).json").path
            }
            
            // Final save with transcript path
            fileService.saveMeeting(meeting)
            
            // Clear current meeting
            currentMeeting = nil
            speechService.clearTranscript()
            
        } catch {
            self.error = .stopFailed(error.localizedDescription)
        }
    }
    
    func pauseMeeting() async {
        guard currentMeeting != nil else { return }
        
        audioService.pauseRecording()
        speechService.stopTranscription()
        stopRecordingTimer()
    }
    
    func resumeMeeting() async {
        guard currentMeeting != nil else { return }
        
        audioService.resumeRecording()
        speechService.startTranscription()
        startRecordingTimer()
    }
    
    // MARK: - Transcript Handling
    private func handleNewTranscriptSegment(_ segments: [TranscriptSegment]) {
        Task { @MainActor in
            // Append new segments to current transcript
            if currentTranscript.isEmpty {
                currentTranscript = segments.map { segment in
                    "[\(DateFormatter.timestamp.string(from: segment.timestamp))] \(segment.speaker ?? "Unknown"): \(segment.text)"
                }.joined(separator: "\n")
            } else {
                let newSegmentText = segments.map { segment in
                    "[\(DateFormatter.timestamp.string(from: segment.timestamp))] \(segment.speaker ?? "Unknown"): \(segment.text)"
                }.joined(separator: "\n")
                currentTranscript += "\n" + newSegmentText
            }
            
            // Save transcript periodically (every 10 segments or every 30 seconds)
            let now = Date()
            if segments.count >= 10 || now.timeIntervalSince(lastTranscriptSave) >= 30 {
                guard let meetingId = currentMeeting?.id else { return }
                
                let transcript = MeetingTranscript(
                    meetingId: meetingId,
                    segments: segments,
                    createdAt: currentMeeting?.startTime ?? now,
                    lastUpdated: now
                )
                
                fileService.saveTranscript(transcript)
                lastTranscriptSave = now
            }
        }
    }
    
    // MARK: - Timer Management
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
    }
    
    // MARK: - Meeting History
    func getMeetings() -> [Meeting] {
        return fileService.meetings
    }
    
    func loadMeetings() async -> [Meeting] {
        fileService.loadMeetings()
        return fileService.meetings
    }
    
    func deleteMeeting(_ meeting: Meeting) {
        fileService.deleteMeeting(meeting)
    }
    
    // MARK: - Search
    func searchMeetings(query: String) -> [Meeting] {
        return fileService.searchMeetings(query: query)
    }
    
    func searchTranscripts(query: String) async -> [TranscriptSegment] {
        return fileService.searchTranscripts(query: query)
    }
    
    // MARK: - Export
    func exportTranscript(for meeting: Meeting, format: ExportFormat) -> String? {
        switch format {
        case .text:
            return fileService.exportTranscriptAsText(for: meeting)
        case .markdown:
            return fileService.exportTranscriptAsMarkdown(for: meeting)
        case .json:
            if let transcript = fileService.loadTranscript(for: meeting.id) {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                if let data = try? encoder.encode(transcript) {
                    return String(data: data, encoding: .utf8)
                }
            }
            return nil
        }
    }
    
    func saveExportedTranscript(_ content: String, for meeting: Meeting, format: ExportFormat) {
        fileService.saveExportedTranscript(content, for: meeting, format: format)
    }
    
    func getTranscript(for meetingId: UUID) -> MeetingTranscript? {
        return fileService.loadTranscript(for: meetingId)
    }
    
    // MARK: - Audio Settings
    func setAudioInputGain(_ gain: Float) {
        // This would require additional audio engine configuration
        print("Audio input gain set to: \(gain)")
    }
    
    func setAudioOutputVolume(_ volume: Float) {
        // This would require additional audio engine configuration
        print("Audio output volume set to: \(volume)")
    }
}

// MARK: - Meeting Manager Errors
enum MeetingManagerError: LocalizedError {
    case permissionDenied
    case startFailed(String)
    case stopFailed(String)
    case pauseFailed(String)
    case resumeFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case searchFailed(String)
    case exportFailed(String)
    case audioError(String)
    case speechError(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied for audio recording or speech recognition"
        case .startFailed(let message):
            return "Failed to start meeting: \(message)"
        case .stopFailed(let message):
            return "Failed to stop meeting: \(message)"
        case .pauseFailed(let message):
            return "Failed to pause meeting: \(message)"
        case .resumeFailed(let message):
            return "Failed to resume meeting: \(message)"
        case .loadFailed(let message):
            return "Failed to load meetings: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete meeting: \(message)"
        case .searchFailed(let message):
            return "Failed to search: \(message)"
        case .exportFailed(let message):
            return "Failed to export transcript: \(message)"
        case .audioError(let message):
            return "Audio error: \(message)"
        case .speechError(let message):
            return "Speech recognition error: \(message)"
        }
    }
}

// MARK: - Meeting Extension for Mutability
extension Meeting {
    mutating func updateTranscriptPath(_ path: String) {
        self.transcriptPath = path
    }
}