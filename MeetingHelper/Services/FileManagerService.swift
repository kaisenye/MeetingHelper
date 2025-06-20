import Foundation

class FileManagerService: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var error: FileManagerError?
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let meetingsDirectory: URL
    private let transcriptsDirectory: URL
    private let audioDirectory: URL
    
    // JSON Encoder/Decoder
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        // Setup directories
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        meetingsDirectory = documentsDirectory.appendingPathComponent("MeetingHelper")
        transcriptsDirectory = meetingsDirectory.appendingPathComponent("Transcripts")
        audioDirectory = meetingsDirectory.appendingPathComponent("Audio")
        
        // Configure JSON encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // Create directories if they don't exist
        createDirectoriesIfNeeded()
        
        // Load existing meetings
        loadMeetings()
    }
    
    // MARK: - Directory Management
    
    private func createDirectoriesIfNeeded() {
        let directories = [meetingsDirectory, transcriptsDirectory, audioDirectory]
        
        for directory in directories {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                self.error = .directoryCreationFailed(error.localizedDescription)
                print("❌ Failed to create directory: \(directory.path)")
            }
        }
    }
    
    func getMeetingsDirectoryURL() -> URL {
        return meetingsDirectory
    }
    
    func getTranscriptsDirectoryURL() -> URL {
        return transcriptsDirectory
    }
    
    func getAudioDirectoryURL() -> URL {
        return audioDirectory
    }
    
    // MARK: - Meeting Management
    
    func saveMeeting(_ meeting: Meeting) {
        do {
            let meetingData = try encoder.encode(meeting)
            let meetingURL = meetingsDirectory.appendingPathComponent("\(meeting.id.uuidString).json")
            try meetingData.write(to: meetingURL)
            
            // Update local array if not already present
            if !meetings.contains(where: { $0.id == meeting.id }) {
                meetings.append(meeting)
                meetings.sort { $0.startTime > $1.startTime } // Sort by most recent first
            }
            
            print("✅ Meeting saved: \(meeting.title)")
        } catch {
            self.error = .saveFailed(error.localizedDescription)
            print("❌ Failed to save meeting: \(error)")
        }
    }
    
    func loadMeetings() {
        do {
            let meetingFiles = try fileManager.contentsOfDirectory(at: meetingsDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            meetings.removeAll()
            
            for file in meetingFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let meeting = try decoder.decode(Meeting.self, from: data)
                    meetings.append(meeting)
                } catch {
                    print("⚠️ Failed to load meeting from \(file.lastPathComponent): \(error)")
                }
            }
            
            // Sort by most recent first
            meetings.sort { $0.startTime > $1.startTime }
            
            print("📂 Loaded \(meetings.count) meetings")
        } catch {
            self.error = .loadFailed(error.localizedDescription)
            print("❌ Failed to load meetings: \(error)")
        }
    }
    
    func deleteMeeting(_ meeting: Meeting) {
        do {
            // Delete meeting file
            let meetingURL = meetingsDirectory.appendingPathComponent("\(meeting.id.uuidString).json")
            try fileManager.removeItem(at: meetingURL)
            
            // Delete transcript file
            let transcriptURL = transcriptsDirectory.appendingPathComponent("\(meeting.id.uuidString).json")
            if fileManager.fileExists(atPath: transcriptURL.path) {
                try fileManager.removeItem(at: transcriptURL)
            }
            
            // Delete audio file if exists
            let audioURL = audioDirectory.appendingPathComponent("\(meeting.id.uuidString).m4a")
            if fileManager.fileExists(atPath: audioURL.path) {
                try fileManager.removeItem(at: audioURL)
            }
            
            // Remove from local array
            meetings.removeAll { $0.id == meeting.id }
            
            print("🗑️ Meeting deleted: \(meeting.title)")
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
            print("❌ Failed to delete meeting: \(error)")
        }
    }
    
    func updateMeeting(_ meeting: Meeting) {
        do {
            let meetingData = try encoder.encode(meeting)
            let meetingURL = meetingsDirectory.appendingPathComponent("\(meeting.id.uuidString).json")
            try meetingData.write(to: meetingURL)
            
            // Update local array
            if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
                meetings[index] = meeting
            }
            
            print("✅ Meeting updated: \(meeting.title)")
        } catch {
            self.error = .saveFailed(error.localizedDescription)
            print("❌ Failed to update meeting: \(error)")
        }
    }
    
    // MARK: - Transcript Management
    
    func saveTranscript(_ transcript: MeetingTranscript) {
        do {
            let transcriptData = try encoder.encode(transcript)
            let transcriptURL = transcriptsDirectory.appendingPathComponent("\(transcript.meetingId.uuidString).json")
            try transcriptData.write(to: transcriptURL)
            
            print("✅ Transcript saved for meeting: \(transcript.meetingId)")
        } catch {
            self.error = .saveFailed(error.localizedDescription)
            print("❌ Failed to save transcript: \(error)")
        }
    }
    
    func loadTranscript(for meetingId: UUID) -> MeetingTranscript? {
        do {
            let transcriptURL = transcriptsDirectory.appendingPathComponent("\(meetingId.uuidString).json")
            let data = try Data(contentsOf: transcriptURL)
            let transcript = try decoder.decode(MeetingTranscript.self, from: data)
            return transcript
        } catch {
            print("⚠️ Failed to load transcript for meeting \(meetingId): \(error)")
            return nil
        }
    }
    
    func updateTranscript(_ transcript: MeetingTranscript, with newSegment: TranscriptSegment) {
        var updatedTranscript = transcript
        updatedTranscript = MeetingTranscript(
            meetingId: transcript.meetingId,
            segments: transcript.segments + [newSegment],
            createdAt: transcript.createdAt,
            lastUpdated: Date()
        )
        
        saveTranscript(updatedTranscript)
    }
    
    // MARK: - Audio File Management
    
    func audioFileExists(for meetingId: UUID) -> Bool {
        let url = getAudioFileURL(for: meetingId)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func getAudioFileURL(for meetingId: UUID) -> URL {
        return audioDirectory.appendingPathComponent("\(meetingId.uuidString).m4a")
    }
    
    // MARK: - Export Functions
    
    func exportTranscriptAsText(for meeting: Meeting) -> String? {
        guard let transcript = loadTranscript(for: meeting.id) else { return nil }
        
        var text = "Meeting: \(meeting.title)\n"
        text += "Date: \(DateFormatter.timestamp.string(from: meeting.startTime))\n"
        if let endTime = meeting.endTime {
            text += "Duration: \(meeting.startTime.distance(to: endTime).formattedDuration)\n"
        }
        text += "Participants: \(meeting.participants.joined(separator: ", "))\n\n"
        
        for segment in transcript.segments {
            let timestamp = DateFormatter.timestamp.string(from: segment.timestamp)
            text += "[\(timestamp)] \(segment.speaker ?? "Unknown"): \(segment.text)\n"
        }
        
        return text
    }
    
    func exportTranscriptAsMarkdown(for meeting: Meeting) -> String? {
        guard let transcript = loadTranscript(for: meeting.id) else { return nil }
        
        var markdown = "# \(meeting.title)\n\n"
        markdown += "**Date:** \(DateFormatter.timestamp.string(from: meeting.startTime))\n"
        if let endTime = meeting.endTime {
            markdown += "**Duration:** \(meeting.startTime.distance(to: endTime).formattedDuration)\n"
        }
        markdown += "**Participants:** \(meeting.participants.joined(separator: ", "))\n\n"
        markdown += "## Transcript\n\n"
        
        for segment in transcript.segments {
            let timestamp = DateFormatter.timestamp.string(from: segment.timestamp)
            markdown += "**[\(timestamp)] \(segment.speaker ?? "Unknown"):** \(segment.text)\n\n"
        }
        
        return markdown
    }
    
    func saveExportedTranscript(_ content: String, for meeting: Meeting, format: ExportFormat) {
        let fileName: String
        switch format {
        case .text:
            fileName = "\(meeting.title)_\(DateFormatter.filename.string(from: meeting.startTime)).txt"
        case .markdown:
            fileName = "\(meeting.title)_\(DateFormatter.filename.string(from: meeting.startTime)).md"
        case .json:
            fileName = "\(meeting.title)_\(DateFormatter.filename.string(from: meeting.startTime)).json"
        }
        
        let url = transcriptsDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save exported transcript: \(error)")
        }
    }
    
    // MARK: - Search Functions
    
    func searchMeetings(query: String) -> [Meeting] {
        guard !query.isEmpty else { return meetings }
        
        return meetings.filter { meeting in
            meeting.title.localizedCaseInsensitiveContains(query) ||
            meeting.participants.joined(separator: " ").localizedCaseInsensitiveContains(query) ||
            (meeting.summary?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func searchTranscripts(query: String, in meetingId: UUID? = nil) -> [TranscriptSegment] {
        guard !query.isEmpty else { return [] }
        
        var results: [TranscriptSegment] = []
        let meetingsToSearch = meetingId != nil ? meetings.filter { $0.id == meetingId } : meetings
        
        for meeting in meetingsToSearch {
            if let transcript = loadTranscript(for: meeting.id) {
                let matchingSegments = transcript.segments.filter { segment in
                    segment.text.localizedCaseInsensitiveContains(query)
                }
                results.append(contentsOf: matchingSegments)
            }
        }
        
        return results
    }
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case text = "txt"
    case markdown = "md"
    case json = "json"
    
    var fileExtension: String {
        return rawValue
    }
    
    var displayName: String {
        switch self {
        case .text: return "Plain Text"
        case .markdown: return "Markdown"
        case .json: return "JSON"
        }
    }
}

enum FileManagerError: LocalizedError {
    case directoryCreationFailed(String)
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let message):
            return "Directory creation failed: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .loadFailed(let message):
            return "Load failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let meetingFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
    
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    static let filename: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - MeetingTranscript Extension
extension MeetingTranscript {
    func updated(with newSegments: [TranscriptSegment]) -> MeetingTranscript {
        let allSegments = segments + newSegments
        return MeetingTranscript(
            meetingId: meetingId,
            segments: allSegments,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
} 