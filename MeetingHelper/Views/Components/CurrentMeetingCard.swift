//
//  CurrentMeetingCard.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct CurrentMeetingCard: View {
    let meeting: Meeting
    @ObservedObject var meetingManager: MeetingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(meetingManager.isRecording ? Color.red : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(meetingManager.recordingDuration.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Audio level indicator
            if meetingManager.isRecording {
                HStack {
                    Text("Audio Level:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: meetingManager.audioLevel)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            
            // Control buttons
            HStack {
                if meetingManager.isRecording {
                    Button("Pause") {
                        Task { await meetingManager.pauseMeeting() }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Resume") {
                        Task { await meetingManager.resumeMeeting() }
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Stop") {
                    Task { await meetingManager.stopMeeting() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
} 