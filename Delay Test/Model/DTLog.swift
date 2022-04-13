//
//  DTLog.swift
//  Realm SwiftUI Sample
//
//  Created by zhaoxin on 2021/12/21.
//

import Foundation
import RealmSwift
import SwiftUI
import MyHost

class DTLog:Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var startTime = Date()
    @Persisted var interval = 0
    @Persisted var connected = true
    @Persisted var delay = 0
}

struct DisconnectedTimePoint {
    var startTime:Date
    var timeLength:Int
}

struct FrequencyStaticsticsToNow:StaticsticsMethodHelper, Identifiable {
    let id:String = UUID().uuidString
    
    var count:Int
    var max:Int
    var logs:Slice<Results<DTLog>>?
    var disconnectedTimePoints:[DisconnectedTimePoint]
    
    init(count:Int, logs:Results<DTLog>) {
        let min = min(logs.count, count)
        self.count = min
        self.max = count
        let logs = logs.sorted(byKeyPath: "startTime", ascending: false)[0..<min]
        self.logs = logs
        self.disconnectedTimePoints = getDisconnectedTimePoints(with: logs)
    }
}

struct DurationStaticsticsToNow:StaticsticsMethodHelper, Identifiable {
    var id: Int { timeLength }
    
    var timeLength:Int
    var logs:Slice<Results<DTLog>>?
    var disconnectedTimePoints:[DisconnectedTimePoint]
    
    init(timeLength:Int, logs:Results<DTLog>) {
        self.timeLength = timeLength
        let logs:Slice<Results<DTLog>>? = {
            let now = Date()
            let date = Date(timeInterval: -Double(timeLength * 60), since: now) as NSDate
            let logs = logs.filter(NSPredicate(format: "startTime>%@", date))
            
            return logs[0..<logs.count]
        }()
        self.logs = logs
        self.disconnectedTimePoints = {
            if let logs = logs {
                return getDisconnectedTimePoints(with: logs)
            }
            
            return []
        }()
    }
}

protocol StaticsticsMethodHelper {
    var disconnectedTimePoints:[DisconnectedTimePoint] { get set }
    var logs:Slice<Results<DTLog>>? { get set }
    
    func goodsIn() -> Double
    func getLDT() -> Int
    func getADT() -> Int
    func getTDT() -> Int
}

extension StaticsticsMethodHelper {
    func goodsIn() -> Double {
        guard let logs = logs else {
            return 0
        }

        if logs.isEmpty {
            return 0
        }
        
        let goodsIn = logs.filter { $0.connected }
        
        return Double(goodsIn.count) / Double(logs.count)
    }
    
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

func getDisconnectedTimePoints(with logs:Slice<Results<DTLog>>) -> [DisconnectedTimePoint] {
    // get disconnectedTimePoints
    var disconnectedTimePoints = [DisconnectedTimePoint]()
    var disconnectedTimePoint:DisconnectedTimePoint? = nil
    
    for log in logs {
        if disconnectedTimePoint != nil {
            if log.connected {
                disconnectedTimePoints.append(disconnectedTimePoint!)
                disconnectedTimePoint = nil
            } else {
                disconnectedTimePoint!.timeLength += log.interval
            }
        } else {
            if log.connected {
                
            } else {
                disconnectedTimePoint = DisconnectedTimePoint(startTime: log.startTime, timeLength: log.interval)
            }
        }
    }
    
    if let disconnectedTimePoint = disconnectedTimePoint {
        disconnectedTimePoints.append(disconnectedTimePoint)
    }
    
    return disconnectedTimePoints
}

struct DTResult {
    var state:State = .stop
    
    func getText() -> Text {
        switch state {
        case .testing:
            return Text("Testing...")
                .foregroundColor(.blue)
        case .stop:
            return Text("Stopped.")
        case .result(let log):
            let content:String
            let color:Color
            
            guard !log.isInvalidated else {
                return Text("No data.")
                    .foregroundColor(.green)
            }
            
            if log.connected {
                content = String.localizedStringWithFormat(NSLocalizedString("Good in %dms.", comment: ""), log.delay)
                color = .green
            } else {
                if log.delay == -1 {
                    content = NSLocalizedString("Connection timed out.", comment: "")
                } else {
                    content = String.localizedStringWithFormat(NSLocalizedString("Failed in %dms.", comment: ""), -log.delay)
                }
                
                color = .red
            }
            
            return Text(content)
                .foregroundColor(color)
        }
    }
    
    enum State {
        case testing
        case stop
        case result(log:DTLog)
    }
}


