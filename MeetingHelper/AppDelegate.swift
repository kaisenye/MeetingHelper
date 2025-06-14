//
//  AppDelegate.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }
    }
}
