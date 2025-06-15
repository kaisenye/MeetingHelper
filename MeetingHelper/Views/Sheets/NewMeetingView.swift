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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("New Meeting")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Title")
                        .font(.headline)
                    TextField("Enter meeting title", text: $meetingTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)
                    TextField("Enter meeting description", text: $meetingDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minWidth: 100, minHeight: 40)
                    
                    Button("Start Meeting") {
                        startMeeting()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .frame(minWidth: 120, minHeight: 40)
                    .disabled(meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .frame(minWidth: 400, maxWidth: 500)
            .frame(minHeight: 300)
        }
    }
    
    private func startMeeting() {
        let title = meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await meetingManager.startMeeting(title: title)
        }
        dismiss()
    }
}

#Preview {
    NewMeetingView(meetingManager: MeetingManager())
} 
