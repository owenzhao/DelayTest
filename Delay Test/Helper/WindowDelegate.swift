//
//  WindowDelegate.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/31.
//

import Foundation
import AppKit
import SwiftUI

class WindowDelegate:NSObject, NSWindowDelegate {
    var tag:TagType
    
    init(tag:TagType) {
        self.tag = tag
    }
    
    func windowShouldClose(_ window: NSWindow) -> Bool {
        if tag == .other {
            return true
        }
        
        if NSApp.orderedWindows.filter({
            if let windowDelegate = $0.delegate as? WindowDelegate {
                return windowDelegate.tag == .main
            }
            
            return false
        }).count > 1 {
            return true
        }
        
        NSApp.hide(self)
        
        return false
    }

    enum TagType {
        case main
        case other
    }
}
