//
//  ActiveMeetingView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct ActiveMeetingView: View {
    @ObservedObject var meetingManager: MeetingManager
    
    var body: some View {
        VStack(spacing: 20) {
            if let meeting = meetingManager.currentMeeting {
                // Meeting info
                VStack(spacing: 8) {
                    Text(meeting.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Recording: \(meetingManager.recordingDuration.formattedDuration)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(meetingManager.isRecording ? Color.red : Color.orange)
                            .frame(width: 12, height: 12)
                        
                        Text(meetingManager.isRecording ? "Recording" : "Paused")
                            .font(.headline)
                    }
                }
                
                // Audio level
                if meetingManager.isRecording {
                    VStack {
                        Text("Audio Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: meetingManager.audioLevel)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Live transcript
                if !meetingManager.currentTranscript.isEmpty {
                    ScrollView {
                        Text(meetingManager.currentTranscript)
                            .font(.body)
                            .padding()
                    }
                    .frame(maxHeight: 300)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
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
                    
                    Button("Stop Meeting") {
                        Task { await meetingManager.stopMeeting() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
} 