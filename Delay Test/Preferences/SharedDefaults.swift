//
//  SharedDefaults.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/30.
//

import Foundation
import Defaults

let sharedDefaults = UserDefaults(suiteName: "96NM39SGJ5.group.com.parussoft.Delay-Test.shared")!

extension Defaults.Keys {
//    MARK: - Shared
    static let launchWhenLogin = Key<Bool>("launchWhenLogin", default: true, suite: sharedDefaults)
    static let startFromLauncher = Key<Bool>("startFromLauncher", default: false, suite: sharedDefaults)
//    MARK: - Debug
//    static let startFromLauncher = Key<Bool>("startFromLauncher", default: true, suite: sharedDefaults)
}
