//
//  FloatingWindow.swift
//  MeetingHelper
//
//  Created by Kaisen Ye on 6/13/25.
//

import Cocoa

class FloatingWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            super.keyDown(with: event)
            return
        }

        // Get current window position
        var frame = self.frame
        let moveAmount: CGFloat = 60

        switch event.keyCode {
        case 123: // Left arrow
            frame.origin.x -= moveAmount
        case 124: // Right arrow
            frame.origin.x += moveAmount
        case 125: // Down arrow
            frame.origin.y -= moveAmount
        case 126: // Up arrow
            frame.origin.y += moveAmount
        default:
            super.keyDown(with: event)
            return
        }

        self.setFrame(frame, display: true, animate: true)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}
