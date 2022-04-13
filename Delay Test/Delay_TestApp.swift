//
//  Delay_TestApp.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/20.
//

import SwiftUI
import AppKit
import Preferences
import PreferencePanes
import Defaults
import UserNotifications
import RealmSwift
import ServiceManagement
import MyHost
import SpeedTestServiceNotification

class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.startFromLauncher) private var startFromLauncher
    @Default(.launchWhenLogin) private var launchWhenLogin
    @Default(.runImmediately) private var runImmediately
    @Default(.startButtonDisabled) private var startButtonDisabled
    @Default(.stopButtonDisabled) private var stopButtonDisabled
    @Default(.notifyOnceWhenNetworkGood) private var notifyOnceWhenNetworkGood
    @Default(.statusBarStyle) private var statusBarStyle
    @Default(.goodText) private var goodText
    @Default(.failText) private var failText
    @Default(.goodTextColor) private var goodTextColor
    @Default(.failTextColor) private var failTextColor
    
    lazy private var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    lazy private var canEnterFullInternet = true
    private var updateFailTextTimer:Timer!
    
    var host:MyHost!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenubarTray()
        constructMenu()
        registerNotification()
        
        if !SMLoginItemSetEnabled("com.parussoft.Delay-Test-Launcher" as CFString, launchWhenLogin) {
            print("Login Item Was Not Successful")
        }
        
        if runImmediately  {
            if !startButtonDisabled {
                startButtonDisabled.toggle()
                stopButtonDisabled.toggle()
            }
            
            NotificationCenter.default.post(name: SpeedTestServiceNotification.start, object: self)
        }
        
        // run myhost
        MyHost.start()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        unregisterNotification()
        
//    MARK: - Debug
//        Defaults.reset(.startFromLauncher)
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(forName: Notification.Name.statusBarSettingsDidChanged, object: nil, queue: nil) { notification in
            DispatchQueue.main.async { [self] in
                setupMenubarTray()
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.statusBarStyleDidChanged, object: nil, queue: nil) { notification in
            DispatchQueue.main.async { [self] in
                setupMenubarTray()
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.dtLogNewLog, object: nil, queue: nil) { notification in
            DispatchQueue.main.async { [self] in
                setupMenubarTray()
            }
        }
        
        NotificationCenter.default.addObserver(forName: SpeedTestServiceNotification.stop, object: nil, queue: nil) { [self] _ in
            if updateFailTextTimer != nil {
                updateFailTextTimer.invalidate()
                updateFailTextTimer = nil
            }
        }
    }
    
    private func addNotification(with delay:Int) async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Network Connected", comment: "")
        content.body = String.localizedStringWithFormat(NSLocalizedString("Good in %dms.", comment: ""), delay)
        content.sound = .default
        let request = UNNotificationRequest(identifier: "Network Good Request",
                                            content: content,
                                            trigger: nil)
        try await center.add(request)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.statusBarSettingsDidChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.statusBarStyleDidChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.dtLogNewLog, object: nil)
        NotificationCenter.default.removeObserver(self, name: SpeedTestServiceNotification.stop, object: nil)
    }
}

@main
struct Delay_TestApp: SwiftUI.App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let GeneralPreferenceViewController: () -> PreferencePane = {
        let paneView = Preferences.Pane(
            identifier: .general,
            title: NSLocalizedString("General", comment: ""),
            toolbarIcon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General preferences")!
        ) {
            GeneralSettingsView()
        }

        return Preferences.PaneHostingController(pane: paneView)
    }
    
    let StatusBarPreferenceViewController: () -> PreferencePane = {
        let paneView = Preferences.Pane(
            identifier: .statusBar,
            title: NSLocalizedString("Status Bar", comment: ""),
            toolbarIcon: NSImage(systemSymbolName: "menubar.dock.rectangle.badge.record", accessibilityDescription: "Status Bar")!) {
                StatusBarSettingView()
            }
        
        return Preferences.PaneHostingController(pane: paneView)
    }
    
    @State private var service = SpeedTestService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(service: $service,
                        enthernet: NetworkLink(MAC: ""),
                        wifi: NetworkLink(MAC: ""),
                        internetIPV4: "",
                        internetIPV6: "")
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.appSettings) {
                Button("Preferences...") {
                    PreferencesWindowController(
                        preferencePanes: [
                            GeneralPreferenceViewController(),
                            StatusBarPreferenceViewController()
                        ],
                        style: .toolbarItems,
                        animated: true,
                        hidesToolbarForSingleItem: true
                    ).show()
                }.keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            }
        }
        .windowToolbarStyle(.unified)
    }
}

// MARK: - setup menubar button
extension AppDelegate {
    private func setupMenubarTray() {
        if let button = statusItem.button {
            var connected = true
            // get last result
            let realm = try! Realm()
            if let result = realm.objects(DTLog.self).sorted(byKeyPath: "startTime", ascending: false).first {
                connected = result.connected
                
                if connected {
                    if !canEnterFullInternet {
                        canEnterFullInternet = true
                        stopUpdateFailTextTimer()
                    }
                } else {
                    if canEnterFullInternet {
                        canEnterFullInternet.toggle()
                    }
                }
                
                if notifyOnceWhenNetworkGood && connected {
                    let delay = result.delay
                    
                    defer {
                        $notifyOnceWhenNetworkGood.wrappedValue.toggle()
                    }
                    
                    Task {
                        let settings = await UNUserNotificationCenter.current().notificationSettings()
                        
                        switch settings.authorizationStatus {
                        case .authorized, .provisional:
                            try await addNotification(with: delay)
                        default:
                            break
                        }
                    }
                }
            }
            
            statusItem.button?.image = nil
            statusItem.button?.title = ""
            
            switch statusBarStyle {
            case .icon:
                if connected {
                    button.image = NSImage(imageLiteralResourceName: "snail")
                } else {
                    if updateFailTextTimer == nil {
                        startUpdateFailTextTimer()
                    }
                }
            case .text:
                if connected {
                    button.attributedTitle = NSAttributedString(string: goodText,
                                                                attributes: [.foregroundColor : NSColor(goodTextColor.color)])
                } else {
                    if updateFailTextTimer == nil {
                        startUpdateFailTextTimer()
                    }
                }
            }
        }
    }
// MARK: - update fail text
    private func startUpdateFailTextTimer() {
        let startTime = ProcessInfo.processInfo.systemUptime
        
        updateFailTextTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [self] _ in
            if let button = statusItem.button {
                let now = ProcessInfo.processInfo.systemUptime
                let counter = String(Int(now - startTime))
                
                let attributeString = NSMutableAttributedString(string: counter,
                                                            attributes: [.foregroundColor : NSColor(failTextColor.color),
                                                                         .baselineOffset: -1])
                
                switch statusBarStyle {
                case .icon:
                    let image = NSImage(imageLiteralResourceName: "color-snail")
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    let mutableAttibulteString = NSMutableAttributedString(attachment: attachment)
                    mutableAttibulteString.addAttributes([.baselineOffset: -3], range: NSRange(location: 0, length: mutableAttibulteString.length))
                    attributeString.insert(mutableAttibulteString, at: 0)
                    button.attributedTitle = attributeString
                case .text:
                    attributeString.insert(NSAttributedString(string: failText), at: 0)
                    button.attributedTitle = attributeString
                }
            }
        })
    }
    
    private func stopUpdateFailTextTimer() {
        if updateFailTextTimer != nil {
            updateFailTextTimer.invalidate()
            updateFailTextTimer = nil
        }
    }
    
    private func unhide() {
        NSApp.unhide(nil)
    }
    
    private func constructMenu() {
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(withTitle: NSLocalizedString("Delay Test", comment: ""),
                     action: #selector(showMainApp(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: NSLocalizedString("Notify Once When Network Good", comment: ""), action: #selector(notifyOnceWhenNetworkGood(_:)), keyEquivalent: "")
        menu.addItem(withTitle: NSLocalizedString("About", comment: ""), action: #selector(NSApp.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        menu.addItem(withTitle: NSLocalizedString("Quit", comment: ""), action: #selector(quit), keyEquivalent: "")
        statusItem.menu = menu
    }

    @objc private func showMainApp(_ sender: Any?) {
        if NSApp.isActive {
            
        } else {
            if NSApp.isHidden {
                unhide()
            }
        }
        
        NSApp.orderedWindows.forEach {
            if $0.isMiniaturized {
                $0.deminiaturize(self)
            }
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func notifyOnceWhenNetworkGood(_ sender: Any?) {
        notifyOnceWhenNetworkGood.toggle()
        
        Task {
            try await requestAuthorizationPushNotification()
        }
    }
    
    private func requestAuthorizationPushNotification() async throws {
        let _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert])
    }
    
    @objc private func quit() {
        guard canQuit() else {
            NSSound.beep()
            return
        }
        
        ProcessInfo.processInfo.enableSuddenTermination()
        NSApp.terminate(nil)
    }
    
    private func canQuit() -> Bool {
        for window in NSApp.windows {
            if window.isModalPanel {
                return false
            }
        }
        
        return true
    }
}

// MARK: -
extension AppDelegate:NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        if let menuItem = menu.item(withTitle: NSLocalizedString("Notify Once When Network Good", comment: "")) {
            menuItem.state = (notifyOnceWhenNetworkGood == true) ? .on : .off
        }
    }
}

// MARK: - hide delegate
extension AppDelegate {
    func applicationDidHide(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidUnhide(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
