//
//  NewMeetingView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct NewMeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var meetingManager: MeetingManager
    
    @State private var meetingTitle = ""
    @State private var meetingDescription = ""
    @State private var selectedAudioSource: AudioSource = .microphone
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("New Meeting")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start recording and transcribing your meeting")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Form section
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Meeting Title")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("Enter meeting title", text: $meetingTitle)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter meeting description (optional)", text: $meetingDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                    }
                    
                    // Audio source selection (future enhancement)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Audio Source")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.blue)
                            Text("Microphone")
                                .font(.body)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    
                    Button(action: startMeeting) {
                        HStack {
                            Image(systemName: "record.circle.fill")
                            Text("Start Meeting")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .disabled(meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 24)
            }
            .navigationTitle("New Meeting")
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startMeeting()
                    }
                    .fontWeight(.semibold)
                    .disabled(meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            })
        }
        .frame(minWidth: 480, maxWidth: 600)
        .frame(minHeight: 500, maxHeight: 700)
    }
    
    private func startMeeting() {
        let title = meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = meetingDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = description.isEmpty ? nil : description
        
        Task {
            await meetingManager.startMeeting(title: title, description: finalDescription)
        }
        dismiss()
    }
}

#Preview {
    NewMeetingView(meetingManager: MeetingManager())
} 
