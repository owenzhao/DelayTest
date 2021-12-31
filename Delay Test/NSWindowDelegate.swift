//
//  NSWindowDelegate.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/31.
//

import Foundation
import AppKit
import SwiftUI

class WindowDelegate:NSObject, NSWindowDelegate {
    func windowShouldClose(_ window: NSWindow) -> Bool {
        if NSApp.orderedWindows.count > 1 {
            return true
        }
        
        window.miniaturize(self)
        
        return false
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        // hide from dock
        NSApp.setActivationPolicy(.accessory)
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        // show in dock
        NSApp.setActivationPolicy(.regular)
    }
}
