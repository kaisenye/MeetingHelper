//
//  MeetingRowView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct MeetingRowView: View {
    let meeting: Meeting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meeting.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(DateFormatter.meetingFormatter.string(from: meeting.startTime))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !meeting.participants.isEmpty {
                Text(meeting.participants.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack {
                Label(meeting.audioSource.rawValue, systemImage: "waveform")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let endTime = meeting.endTime {
                    Text(endTime.timeIntervalSince(meeting.startTime).formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 