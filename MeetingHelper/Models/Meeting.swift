import Foundation

// MARK: - Meeting Models

struct Meeting: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    let startTime: Date
    var endTime: Date?
    let participants: [String]
    var transcriptPath: String
    let audioSource: AudioSource
    var summary: String?
    var description: String?
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    init(title: String, audioSource: AudioSource, participants: [String] = [], description: String? = nil) {
        self.id = UUID()
        self.title = title
        self.startTime = Date()
        self.endTime = nil
        self.participants = participants
        self.transcriptPath = "meetings/\(id.uuidString).json"
        self.audioSource = audioSource
        self.summary = nil
        self.description = description
    }
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Meeting, rhs: Meeting) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Helper method to update meeting details
    mutating func updateDetails(title: String, description: String?) {
        self.title = title
        self.description = description
    }
}

struct TranscriptSegment: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let speaker: String?
    let text: String
    let confidence: Float
    let duration: TimeInterval
    
    init(text: String, confidence: Float, duration: TimeInterval, speaker: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.speaker = speaker
        self.text = text
        self.confidence = confidence
        self.duration = duration
    }
}

struct MeetingTranscript: Codable {
    let meetingId: UUID
    let segments: [TranscriptSegment]
    let createdAt: Date
    let lastUpdated: Date
    
    init(meetingId: UUID, segments: [TranscriptSegment] = [], createdAt: Date = Date(), lastUpdated: Date = Date()) {
        self.meetingId = meetingId
        self.segments = segments
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

enum AudioSource: String, Codable, CaseIterable {
    case systemAudio = "System Audio"
    case microphone = "Microphone"
    case zoom = "Zoom"
    case teams = "Microsoft Teams"
    case googleMeet = "Google Meet"
    case webex = "Webex"
    case other = "Other"
}

// MARK: - LLM Integration Models

struct LLMQuery: Codable {
    let id: UUID
    let meetingId: UUID
    let query: String
    let response: String?
    let timestamp: Date
    
    init(meetingId: UUID, query: String) {
        self.id = UUID()
        self.meetingId = meetingId
        self.query = query
        self.response = nil
        self.timestamp = Date()
    }
}

struct MeetingSummary: Codable {
    let meetingId: UUID
    let keyPoints: [String]
    let actionItems: [String]
    let decisions: [String]
    let participants: [String]
    let topics: [String]
    let generatedAt: Date
    
    init(meetingId: UUID) {
        self.meetingId = meetingId
        self.keyPoints = []
        self.actionItems = []
        self.decisions = []
        self.participants = []
        self.topics = []
        self.generatedAt = Date()
    }
} 