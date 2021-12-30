//
//  StatusBarSettingView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/27.
//

import SwiftUI
import Preferences
import Defaults

struct StatusBarSettingView: View {
    static let settingsDidChanged = Notification.Name("settingsDidChanged")
    
    @Default(.statusBarStyle) private var statusBarStyle
    @Default(.goodText) private var goodText
    @Default(.failText) private var failText
    @Default(.goodTextColor) private var goodTextColor
    @Default(.failTextColor) private var failTextColor
    
    private let contentWidth: Double = 450.0
    
    var body: some View {
        Preferences.Container(contentWidth: contentWidth) {
            Preferences.Section(title: NSLocalizedString("Show As", comment: "")) {
                Picker(selection: $statusBarStyle) {
                    Text("Icon").tag(StatusBarStyle.icon)
                    Text("Text").tag(StatusBarStyle.text)
                } label: {
                }
                .frame(width: 120)
                .onChange(of: statusBarStyle) { _ in
                    NotificationCenter.default.post(name: StatusBarStyle.didChanged, object: self)
                }
                
                switch statusBarStyle {
                case .icon:
                    EmptyView()
                case .text:
                    HStack {
                        TextField("Good", text: $goodText)
                            .foregroundColor(goodTextColor.color)
                            .cornerRadius(10)
                            .frame(width: 120)
                            .onChange(of: goodText) { _ in
                                NotificationCenter.default.post(name: StatusBarSettingView.settingsDidChanged, object: self)
                            }
                        
                        Picker(selection: $goodTextColor) {
                            ForEach(GoodColor.allCases, id: \.self) { color in
                                Text(color.localizedString)
                                    .foregroundColor(color.color)
                                    .tag(color)
                            }
                        } label: {
                        }
                        .frame(width: 120)
                        .onChange(of: goodTextColor) { _ in
                            NotificationCenter.default.post(name: GoodColor.didChanged, object: self)
                        }
                    }
                    
                    HStack {
                        TextField("Fail", text: $failText)
                            .foregroundColor(failTextColor.color)
                            .cornerRadius(10)
                            .frame(width: 120)
                            .onChange(of: goodText) { _ in
                                NotificationCenter.default.post(name: StatusBarSettingView.settingsDidChanged, object: self)
                            }
                        
                        Picker(selection: $failTextColor) {
                            ForEach(FailColor.allCases, id: \.self) { color in
                                Text(color.localizedString)
                                    .foregroundColor(color.color)
                                    .tag(color)
                            }
                        } label: {
                        }
                        .frame(width: 120)
                        .onChange(of: failTextColor) { _ in
                            NotificationCenter.default.post(name: FailColor.didChanged, object: self)
                        }
                    }
                }
            }
        }
    }
}

enum GoodColor:String,CaseIterable,Identifiable, Defaults.Serializable {
    static let didChanged = Notification.Name("didChanged")
    
    var id: String {
        return self.rawValue
    }
    
    case black, blue
    case gray, green
    case white
    
    var localizedString:String {
        switch self {
        case .black:
            return NSLocalizedString("Black", comment: "")
        case .blue:
            return NSLocalizedString("Blue", comment: "")
        case .gray:
            return NSLocalizedString("Gray", comment: "")
        case .green:
            return NSLocalizedString("Green", comment: "")
        case .white:
            return NSLocalizedString("White", comment: "")
        }
    }
    
    var color:Color {
        switch self {
        case .black:
            return .black
        case .blue:
            return .blue
        case .gray:
            return .gray
        case .green:
            return .green
        case .white:
            return .white
        }
    }
}

enum FailColor:String,CaseIterable,Identifiable, Defaults.Serializable {
    static let didChanged = Notification.Name("didChanged")
    
    var id: String {
        return self.rawValue
    }
    
    case black
    case orange, pink, purple
    case red
    case white, yellow
    
    var localizedString:String {
        switch self {
        case .black:
            return NSLocalizedString("Black", comment: "")
        case .orange:
            return NSLocalizedString("Orange", comment: "")
        case .pink:
            return NSLocalizedString("Pink", comment: "")
        case .purple:
            return NSLocalizedString("Purple", comment: "")
        case .red:
            return NSLocalizedString("Red", comment: "")
        case .white:
            return NSLocalizedString("White", comment: "")
        case .yellow:
            return NSLocalizedString("Yellow", comment: "")
        }
    }
    
    var color:Color {
        switch self {
        case .black:
            return .black
        case .orange:
            return .orange
        case .pink:
            return .pink
        case .purple:
            return .purple
        case .red:
            return .red
        case .white:
            return .white
        case .yellow:
            return .yellow
        }
    }
}


struct StatusBarSettingView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarSettingView()
    }
}


