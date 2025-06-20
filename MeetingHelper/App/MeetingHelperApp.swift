//
//  MeetingHelperApp.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import SwiftUI

@main
struct MeetingHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
    }
}
