//
//  MeetingDetailView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct MeetingDetailView: View {
    let meeting: Meeting
    @ObservedObject var meetingManager: MeetingManager
    @State private var transcript: MeetingTranscript?
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Meeting header
            VStack(alignment: .leading, spacing: 8) {
                Text(meeting.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    Text(DateFormatter.meetingFormatter.string(from: meeting.startTime))
                    
                    if let endTime = meeting.endTime {
                        Text("• \(endTime.timeIntervalSince(meeting.startTime).formattedDuration)")
                    }
                    
                    Spacer()
                    
                    Text(meeting.audioSource.rawValue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                if !meeting.participants.isEmpty {
                    Text("Participants: \(meeting.participants.joined(separator: ", "))")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search transcript...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Transcript
            if let transcript = transcript {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredSegments(transcript.segments), id: \.id) { segment in
                            TranscriptSegmentView(segment: segment, searchText: searchText)
                        }
                    }
                    .padding()
                }
            } else {
                Text("No transcript available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .toolbar {
            ToolbarItem {
                Menu("Export") {
                    Button("Export as Text") {
                        exportTranscript(format: .text)
                    }
                    Button("Export as Markdown") {
                        exportTranscript(format: .markdown)
                    }
                    Button("Export as JSON") {
                        exportTranscript(format: .json)
                    }
                }
            }
        }
        .onAppear {
            transcript = meetingManager.getTranscript(for: meeting.id)
        }
    }
    
    private func filteredSegments(_ segments: [TranscriptSegment]) -> [TranscriptSegment] {
        if searchText.isEmpty {
            return segments
        } else {
            return segments.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func exportTranscript(format: ExportFormat) {
        if let content = meetingManager.exportTranscript(for: meeting, format: format) {
            meetingManager.saveExportedTranscript(content, for: meeting, format: format)
        }
    }
} 