//
//  Model.swift
//  Realm SwiftUI Sample
//
//  Created by zhaoxin on 2021/12/21.
//

import Foundation
import RealmSwift
import SwiftUI

class DTLog:Object, ObjectKeyIdentifiable {
    static let newLog = Notification.Name("newLog")
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var startTime = Date()
    @Persisted var interval = 0
    @Persisted var connected = true
    @Persisted var delay = 0
}

struct DisconnectedTimePoint {
    var startTime:Date
    var timeLength:Int
}

struct FrequencyStaticstics:StaticsticsMethodHelper {
    var count:Int
    var max:Int
    var disconnectedTimePoints:[DisconnectedTimePoint]
    
//    MARK: - by Frequency
    func goodsIn(_ logs:Results<DTLog>) -> Double {
        guard !logs.isEmpty else {
            return 0
        }
        
        let logs = logs.sorted(byKeyPath: "startTime", ascending: false)[0..<count]
        
        if logs.isEmpty {
            return 0
        }
        
        let goodsIn = logs.filter { $0.connected }
        
        return Double(goodsIn.count) / Double(logs.count)
    }
}

struct DurationStaticstics:StaticsticsMethodHelper {
    var timeLength:Int
    var disconnectedTimePoints:[DisconnectedTimePoint]
    
//    MARK: - by Duration
    func goodsIn(_ logs:Results<DTLog>) -> Double { // in minutes
        let now = Date()
        let date = Date(timeInterval: -Double(timeLength * 60), since: now) as NSDate
        let logs = logs.filter(NSPredicate(format: "startTime>%@", date))
        
        if logs.isEmpty {
            return 0
        }
        
        let goodsIn = logs.filter { $0.connected }
        
        return Double(goodsIn.count) / Double(logs.count)
    }
}

protocol StaticsticsMethodHelper {
    var disconnectedTimePoints:[DisconnectedTimePoint] { get set}
    
    func goodsIn(_ logs:Results<DTLog>) -> Double
    func getLDT() -> Int
    func getADT() -> Int
    func getTDT() -> Int
}

extension StaticsticsMethodHelper {
    func getLDT() -> Int { // in seconds
        let LDT = disconnectedTimePoints.max(by: { $0.timeLength < $1.timeLength })?.timeLength ?? 0
        
        return Int(LDT)
    }
    
    func getADT() -> Int {
        let ADT:Int = {
            if disconnectedTimePoints.isEmpty {
                return 0
            } else {
                return getTDT() / disconnectedTimePoints.count
            }
        }()
        
        return ADT
    }
    
    func getTDT() -> Int {
        let TDT = disconnectedTimePoints.reduce(0) { partialResult, disconnectedTimePoint in
            partialResult + disconnectedTimePoint.timeLength
        }

        return TDT
    }
}

struct DTResult {
    var string:String = NSLocalizedString("Not test yet.", comment: "")
    var color:Color = .green
}
