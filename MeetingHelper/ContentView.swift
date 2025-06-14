//
//  ContentView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("👋 Meeting Helper")
                .font(.title2)
            Text("I'm always on top!")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .frame(width: 280, height: 160)
    }
}

#Preview {
    ContentView()
}
