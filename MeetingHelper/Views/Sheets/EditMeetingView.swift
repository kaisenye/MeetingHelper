//
//  EditMeetingView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct EditMeetingView: View {
    @ObservedObject var meetingManager: MeetingManager
    let meeting: Meeting
    
    @State private var meetingTitle: String
    @State private var meetingDescription: String
    
    @Environment(\.dismiss) private var dismiss
    
    init(meetingManager: MeetingManager, meeting: Meeting) {
        self.meetingManager = meetingManager
        self.meeting = meeting
        self._meetingTitle = State(initialValue: meeting.title)
        self._meetingDescription = State(initialValue: meeting.description ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Meeting Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter meeting title", text: $meetingTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter meeting description (optional)", text: $meetingDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...5)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Meeting Details") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Date")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(meeting.startTime, formatter: DateFormatter.meetingFormatter)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Duration")
                            .foregroundColor(.secondary)
                        Spacer()
                        if let duration = meeting.duration {
                            Text(duration.formattedDuration)
                                .foregroundColor(.primary)
                        } else {
                            Text("In progress")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    HStack {
                        Text("Audio Source")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(meeting.audioSource.rawValue.capitalized)
                            .foregroundColor(.primary)
                    }
                    
                    if !meeting.participants.isEmpty {
                        HStack(alignment: .top) {
                            Text("Participants")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(meeting.participants.joined(separator: ", "))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }.padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 500, height: 450)
        .navigationTitle("Edit Meeting")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveMeetingChanges()
                }
                .disabled(meetingTitle.isEmpty)
            }
        }
    }
    
    private func saveMeetingChanges() {
        let trimmedTitle = meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = meetingDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        
        meetingManager.updateMeeting(meeting, title: trimmedTitle, description: finalDescription)
        dismiss()
    }
}

#Preview {
    EditMeetingView(meetingManager: MeetingManager(), meeting: Meeting(title: "Sample Meeting", audioSource: .microphone, participants: ["John", "Jane"], description: "This is a sample meeting description"))
} 