//
//  DefaultsKeys.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/27.
//

import Foundation
import Defaults

extension Defaults.Keys {
//    MARK: - General
    static let runImmediately = Key<Bool>("runImmediately", default: true)
    
    static let testFileSize = Key<FileSize>("testFileSize", default: .zero)
    static let testInterval = Key<TestInterval>("testInterval", default: .thirtySeconds)
//    MARK: - Status Bar
    static let statusBarStyle = Key<StatusBarStyle>("statusBarStyle", default: .icon)
    static let goodText = Key<String>("goodText", default: "Good")
    static let failText = Key<String>("failText", default: "Fail")
    static let goodTextColor = Key<GoodColor>("goodColor", default: .labelColor)
    static let failTextColor = Key<FailColor>("failColor", default: .labelColor)
//    MARK: - Status Bar Menu
    static let alwaysOnTop = Key<Bool>("alwaysOnTop", default: false)
    static let notifyOnceWhenNetworkGood = Key<Bool>("notifyOnceWhenNetworkGood", default: false)
    
//    MARK: - Content View
    static let startButtonDisabled = Key<Bool>("startButtonDisabled", default: false)
    static let stopButtonDisabled = Key<Bool>("stopButtonDisabled", default: true)
}
