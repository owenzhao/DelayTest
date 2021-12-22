//
//  Model.swift
//  Realm SwiftUI Sample
//
//  Created by zhaoxin on 2021/12/21.
//

import Foundation
import RealmSwift

class DTLog:Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var startTime = Date()
    @Persisted var interval = 0 // Test Intervals
    @Persisted var connected = true
    @Persisted var delay = 0
}

struct DisconnectedTimePoint {
    var startTime:Date
    var timeLength:Int // in minutes
}

struct FrequencyStaticstics:StaticsticsMethodHelper {
    var count:Int
    var max:Int
    var disconnectedTimePoints:[DisconnectedTimePoint]
    
//    MARK: - by Frequency
    func goodsIn(_ logs:Results<DTLog>) -> Double {
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
        
        return LDT
    }
    
    func getADT() -> Int {
        let ADT:Double = {
            if disconnectedTimePoints.isEmpty {
                return 0
            } else {
                return Double(getTDT()) / Double(disconnectedTimePoints.count)
            }
        }()
        
        return Int(ADT)
    }
    
    func getTDT() -> Int {
        let TDT = disconnectedTimePoints.reduce(0) { partialResult, disconnectedTimePoint in
            partialResult + disconnectedTimePoint.timeLength
        }

        return TDT
    }
}
