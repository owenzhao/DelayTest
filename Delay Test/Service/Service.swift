//
//  Service.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/28.
//

import Foundation
import Defaults
import RealmSwift

class SpeedTestService {
    static let restTimeDidChanged = Notification.Name("restTimeDidChanged")
    
    static let start = Notification.Name("start")
    static let stop = Notification.Name("stop")
    
    
    private var timer:Timer? = nil
    private var restTime:Int = 5
    private var updateTimer:Timer? = nil
    
    private let runLoop = RunLoop.current
    
    
    init() {
        registerNotification()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(forName: SpeedTestService.start, object: nil, queue: nil) { [self] notification in
            Task {
                try await start()
            }
        }
        
        NotificationCenter.default.addObserver(forName: SpeedTestService.stop, object: nil, queue: nil) { [self] notification in
            stop()
        }
    }
    
    func start() async throws {
        // arrange next timer
        arrangeNextTimer()
        // calculate rest timer
        updateCounterDown()
        // speed test
        await runSpeedTest()
    }
    
    private func arrangeNextTimer() {
        restTime = Defaults[.testInterval].rawValue

        let timer = Timer(timeInterval: TimeInterval(Defaults[.testInterval].rawValue), repeats: true, block: { [self] _ in
            restTime = Defaults[.testInterval].rawValue
            
            Task {
                await runSpeedTest()
            }
        })
        
        runLoop.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func runSpeedTest() async {
        let log = DTLog()
        
        do {
            // speed test
            try await speedTest(log: log)
        } catch {
            log.connected = false
            log.delay = -1
        }
        
        log.interval = Defaults[.testInterval].rawValue
        
        // save log
        save(log)
        // send notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: DTLog.newLog, object: self, userInfo: ["log":log])
        }
    }
    
    private func updateCounterDown() {
        let updateTimer = Timer(timeInterval: 1, repeats: true) { [self] _ in
            restTime -= 1
            NotificationCenter.default.post(name: SpeedTestService.restTimeDidChanged, object: self, userInfo: ["restTime":restTime])
        }
        
        runLoop.add(updateTimer, forMode: .common)
        self.updateTimer = updateTimer
    }
    
    private func save(_ log:DTLog) {
        DispatchQueue.main.async {
            let realm = try! Realm()
            try! realm.write {
                realm.add(log, update: .all)
            }
        }
    }
    
    private func speedTest(log:DTLog) async throws{
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 10.0
        sessionConfig.timeoutIntervalForResource = 20.0
        let session = URLSession(configuration: sessionConfig)
        let url = getURL()
        
        let startTime = ProcessInfo.processInfo.systemUptime
        let (_, response) = try await session.data(from: url)
        let endTime = ProcessInfo.processInfo.systemUptime
        let delay = Int((endTime - startTime) * 1000)
                
        if (response as! HTTPURLResponse).statusCode == 200 {
            log.delay = delay
        } else {
            log.delay = -delay
            log.connected = false
        }
    }
    
    private func getURL() -> URL {
        switch Defaults[.testFileSize] {
        case .zero:
            return URL(string: "https://github.com/owenzhao/DeleyTest/blob/00f6bc63be1ed5e6448d749c82d423aaa02f7185/files/0KB.file")!
        case .one:
            return URL(string: "https://github.com/owenzhao/DeleyTest/blob/00f6bc63be1ed5e6448d749c82d423aaa02f7185/files/1B.file")!
        case .oneKB:
            return URL(string: "https://github.com/owenzhao/DeleyTest/blob/00f6bc63be1ed5e6448d749c82d423aaa02f7185/files/1KB.file")!
        case .tenKB:
            return URL(string: "https://github.com/owenzhao/DeleyTest/blob/8f77c127ec3d3fbafe117b9a7137d3757c93316d/files/10KB.file")!
        case .hundredKB:
            return URL(string: "https://github.com/owenzhao/DeleyTest/blob/00f6bc63be1ed5e6448d749c82d423aaa02f7185/files/100KB.file")!
        }
    }
    
    func stop() {
        timer?.invalidate()
        updateTimer?.invalidate()
        
        NotificationCenter.default.post(name: SpeedTestService.restTimeDidChanged, object: self, userInfo: ["restTime":0])
    }
    
    func restart() async throws {
        stop()
        try await start()
    }
}
