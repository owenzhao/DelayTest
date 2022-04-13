//
//  Service.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/28.
//

import Foundation
import Defaults
import SpeedTestServiceNotification

class SpeedTestService {
    init() {
        registerNotification()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(forName: SpeedTestServiceNotification.start, object: nil, queue: nil) { [self] notification in
            Task {
                try await start()
            }
        }
    }
    
    func start() async throws {
        await runSpeedTest()
    }
    
    private func runSpeedTest() async {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.backgroundRunningTest, object: nil)
        }
        
        let log = DTLog()
        
        do {
            // speed test
            try await speedTest(log: log)
        } catch {
            log.connected = false
            log.delay = -1
        }
        
        log.interval = Defaults[.testInterval].rawValue

        // send notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.dtLogNewLog, object: self, userInfo: ["log":log])
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
    
    func restart() async throws {
        try await start()
    }
}
