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
    @Persisted var interval = 0 // test interval
    @Persisted var connected = true
    @Persisted var delay = 0
}

struct DisconnectedTimePoint {
    var startTime:Date
    var timeLength:Int // in minutes
}

struct Transit {
    var count:Int
    var max:Int
    var disconnectedTimePoints:[DisconnectedTimePoint]
}
