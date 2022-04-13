//
//  Notification.Name+Extension.swift
//  Internet Helper
//
//  Created by zhaoxin on 2022/4/3.
//

import Foundation

extension Notification.Name {
    static let appdelegateOpenLoginView = Notification.Name("appdelegateOpenLoginView")
    static let appdelegateIsLoginChanged = Notification.Name("appdelegateIsLoginChanged")
    
    static let usernameFullnameChanged = Notification.Name("usernameFullnameChanged")
    
    static let dtLogNewLog = Notification.Name("dtLogNewLog")
    
    static let statusBarStyleDidChanged = Notification.Name("statusBarStyleDidChanged")
    
    static let statusBarSettingsDidChanged = Notification.Name("statusBarSettingsDidChanged")
    
    static let goodColorDidChanged = Notification.Name("goodColorDidChanged")
    
    static let failColorDidChanged = Notification.Name("failColorDidChanged")
    
    static let saveScript = Notification.Name("saveScript")
    
    static let backgroundRunningTest = Notification.Name("backgroundRunningTest")
}
