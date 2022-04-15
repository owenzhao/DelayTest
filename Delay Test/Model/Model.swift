//
//  Model.swift
//  Delay Test
//
//  Created by zhaoxin on 2022/4/13.
//

import Foundation
import RealmSwift
import Defaults

class Model:ObservableObject {
    func clear() {
        let realm = try! Realm()
        try! realm.write({
            realm.deleteAll()
        })
    }
    
    func save(_ log:DTLog) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(log, update: .all)
        }
    }
}

