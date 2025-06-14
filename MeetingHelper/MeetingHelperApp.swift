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
                .frame(width: 300, height: 200)
        }
    }
}
