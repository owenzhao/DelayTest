//
//  IHWindowSize.swift
//  Internet Helper
//
//  Created by zhaoxin on 2022/4/7.
//

import Foundation

struct IHWindowSize {
    static let mainWindow = IHSize(minWidth: 1024, idealHeight: 556)
    static let secondModal = IHSize(width: 400, height: 300)
    static let scriptItemView = IHSize(width: 600, height: 350)
    static let firstModal = IHSize(width: 800, height: 400)
    static let loginView = IHSize(width: 800)
}

struct IHImageSize {
    static let appImage = IHSize(width: 48, height: 48)
}

struct IHViewSize {
    static let picker = IHSize(width: 200)
    static let datePicker = IHSize(width: 180)
    static let smallPicker = IHSize(width: 120)
    static let scriptItemView = IHSize(minWidth: 200, minHeight: 150)
    static let loginText = IHSize(maxWidth: .infinity, maxHeight: .infinity)
    static let button = IHSize(width: 400, height: 40)
}

struct IHSheetSize {
    static let scriptTestRunAlert = IHSize(width: 400, height: 300)
}

struct IHSize {
    var minWidth:CGFloat? = nil
    var minHeight:CGFloat? = nil
    
    var idealWidth:CGFloat? = nil
    var idealHeight:CGFloat? = nil
    
    var maxWidth:CGFloat? = nil
    var maxHeight:CGFloat? = nil
    
    var width:CGFloat? = nil
    var height:CGFloat? = nil
}


