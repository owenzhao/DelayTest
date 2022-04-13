//
//  GeneralSettingsView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/26.
//

import SwiftUI
import Preferences
import Defaults

struct GeneralSettingsView: View {
    @Default(.launchWhenLogin) private var launchWhenLogin
    @Default(.runImmediately) private var runImmediately
    
    private let contentWidth: Double = 450.0
    
    var body: some View {
        Preferences.Container(contentWidth: contentWidth) {            
            Preferences.Section(title: NSLocalizedString("When Login", comment: "")) {
                Toggle(isOn: $launchWhenLogin) {
                    Text("Auto Launch.")
                }
                
                Toggle(isOn: $runImmediately) {
                    Text("Run Immediately.")
                }
            }
        }
    }
}

enum StatusBarStyle:String, CaseIterable, Identifiable, Defaults.Serializable {
    var id: String {
        return self.rawValue
    }
    
    case icon
    case text
}

enum FileSize:Int, CaseIterable, Identifiable, Defaults.Serializable {
    var id: Int {
        self.rawValue
    }
    
    case zero = 0
    case one = 1
    case oneKB = 1024
    case tenKB = 10240
    case hundredKB = 102400
    
    var localizedString:String {
        switch self {
        case .zero:
            return NSLocalizedString("0B", comment: "")
        case .one:
            return NSLocalizedString("1B", comment: "")
        case .oneKB:
            return NSLocalizedString("1KB", comment: "")
        case .tenKB:
            return NSLocalizedString("10KB", comment: "")
        case .hundredKB:
            return NSLocalizedString("100KB", comment: "")
        }
    }
}

enum TestInterval:Int, CaseIterable, Identifiable, Defaults.Serializable {
    var id: Int {
        self.rawValue
    }
    
    case tenSeconds = 10
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300
    case tenMinutes = 600
    
    var localizedString:String {
        switch self {
        case .tenSeconds:
            return NSLocalizedString("10s", comment: "")
        case .thirtySeconds:
            return NSLocalizedString("30s", comment: "")
        case .oneMinute:
            return NSLocalizedString("1m", comment: "")
        case .fiveMinutes:
            return NSLocalizedString("5m", comment: "")
        case .tenMinutes:
            return NSLocalizedString("10m", comment: "")
        }
    }
}

extension Preferences.PaneIdentifier {
    static let general = Self("general")
    static let database = Self("database")
    static let statusBar = Self("statusBar")
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
