//
//  ContentView.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var meetingManager = MeetingManager()
    @State private var showingNewMeetingSheet = false
    @State private var showingMeetingDetail = false
    @State private var showingEditMeetingSheet = false
    @State private var selectedMeeting: Meeting?
    @State private var meetingToEdit: Meeting?
    @State private var searchText = ""
    
    // Computed property to avoid multiple updates per frame
    private var filteredMeetings: [Meeting] {
        let meetings = meetingManager.getMeetings()
        if searchText.isEmpty {
            return meetings
        } else {
            return meetings.filter { meeting in
                meeting.title.localizedCaseInsensitiveContains(searchText) ||
                meeting.participants.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                (meeting.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Header with controls
                headerView
                
                Divider()
                
                // Meeting list
                meetingListView
            }
            .navigationTitle("Meetings")
        } detail: {
            if let selection = selectedMeeting {
                MeetingDetailView(meeting: selection, meetingManager: meetingManager)
            } else if meetingManager.currentMeeting != nil {
                ActiveMeetingView(meetingManager: meetingManager)
            } else {
                EmptyDetailView()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    toggleSidebar()
                }) {
                    Image(systemName: "sidebar.leading")
                }

                Button(action: {
                    showingNewMeetingSheet = true
                }) {
                    Label("New Meeting", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewMeetingSheet) {
            NewMeetingView(meetingManager: meetingManager)
        }
        .sheet(isPresented: $showingEditMeetingSheet) {
            if let meetingToEdit = meetingToEdit {
                EditMeetingView(meetingManager: meetingManager, meeting: meetingToEdit)
            }
        }
        .alert("Error", isPresented: .constant(meetingManager.error != nil)) {
            Button("OK") {
                meetingManager.error = nil
            }
        } message: {
            Text(meetingManager.error?.localizedDescription ?? "")
        }
        .onAppear {
            // Load meetings when the view appears
            Task {
                await meetingManager.loadMeetings()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Current meeting status
            if let currentMeeting = meetingManager.currentMeeting {
                CurrentMeetingCard(meeting: currentMeeting, meetingManager: meetingManager)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search meetings...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Meeting List View
    
    private var meetingListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Top padding
                Color.clear.frame(height: 12)
                
                ForEach(filteredMeetings, id: \.id) { meeting in
                    MeetingRowView(meeting: meeting)
                        .tag(meeting)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedMeeting?.id == meeting.id ? Color.accentColor.opacity(0.1) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMeeting = meeting
                        }
                        .contextMenu {
                            Button("Edit") {
                                editMeeting(meeting)
                            }
                            Button("Export Transcript") {
                                exportTranscript(for: meeting)
                            }
                            Button("Delete", role: .destructive) {
                                deleteMeeting(meeting)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                }
                
                // Bottom padding
                Color.clear.frame(height: 12)
            }
        }
        .background(Color(.windowBackgroundColor))
        .scrollIndicators(.visible)
    }
    
    // MARK: - Actions
    
    private func editMeeting(_ meeting: Meeting) {
        meetingToEdit = meeting
        showingEditMeetingSheet = true
    }
    
    private func exportTranscript(for meeting: Meeting) {
        // Export functionality - could show a sheet with format options
        if let content = meetingManager.exportTranscript(for: meeting, format: .text) {
            meetingManager.saveExportedTranscript(content, for: meeting, format: .text)
        }
    }
    
    private func deleteMeeting(_ meeting: Meeting) {
        meetingManager.deleteMeeting(meeting)
        // Clear selection if the deleted meeting was selected
        if selectedMeeting?.id == meeting.id {
            selectedMeeting = nil
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// MARK: - Extensions

#Preview {
    ContentView()
} 
