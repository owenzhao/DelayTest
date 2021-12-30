//
//  AppDelegate.swift
//  Delay Test Launcher
//
//  Created by zhaoxin on 2021/12/29.
//

import Cocoa
import Defaults

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Defaults[.startFromLauncher] = true
        
        let pathComponents = Bundle.main.bundleURL.pathComponents
        let mainRange = 0..<(pathComponents.count - 4)
        let mainPath = pathComponents[mainRange].joined(separator: "/")
//        try! NSWorkspace.shared.launchApplication(at: URL(fileURLWithPath: mainPath, isDirectory: false), options: [], configuration: [:])
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: mainPath, isDirectory: false),
                                           configuration: NSWorkspace.OpenConfiguration(),
                                           completionHandler: nil)
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

