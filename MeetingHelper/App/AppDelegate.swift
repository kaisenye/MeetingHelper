//
//  AppDelegate.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: FloatingWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()

        // Create the custom FloatingWindow
        let window = FloatingWindow(
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 200),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.setFrameAutosaveName("Main Window")
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window) // To ensure it receives key events

        self.window = window
    }
}
