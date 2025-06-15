//
//  TranscriptSegmentView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct TranscriptSegmentView: View {
    let segment: TranscriptSegment
    var searchText: String = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(DateFormatter.timestampFormatter.string(from: segment.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let speaker = segment.speaker {
                    Text(speaker)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                if searchText.isEmpty {
                    Text(segment.text)
                        .font(.body)
                } else {
                    Text(highlightedText(segment.text, searchText: searchText))
                        .font(.body)
                }
                
                if segment.confidence < 0.8 {
                    Text("Low confidence")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func highlightedText(_ text: String, searchText: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = attributedString.range(of: searchText, options: .caseInsensitive) {
            attributedString[range].backgroundColor = .yellow
        }
        
        return attributedString
    }
} 