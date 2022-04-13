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
        
        NSApp.hide(self)
        
        return false
    }

}
