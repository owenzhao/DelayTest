//
//  ContentView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/20.
//

import SwiftUI
import RealmSwift

struct ContentView: View {
    @ObservedResults(DTLog.self) var logs
    
    @State private var testFileSize = FileSize.zero
    @State private var testInterval = TestInterval.thirtySeconds
    @State private var stasticalMethod = StatisticalMethod.frequency
    
    @State private var result = NSLocalizedString("Not test yet.", comment: "")
    @State private var resultColor = Color.green
    @State private var timer:Timer? = nil
    
    @State private var restTime:TimeInterval = 0
    
    @State private var updateTimer:Timer? = nil
    
    @State private var startButtonDiabled = false
    @State private var stopButtonDisabled = true
    
    @State private var showLDT = false
    
    var body: some View {
        ScrollView {
            VStack(alignment:.leading) {
                HStack {
                    Picker("Test File", selection: $testFileSize) {
                        ForEach(FileSize.allCases) { fileSize in
                            Text(fileSize.localizedString).tag(fileSize)
                        }
                    }.onChange(of: testFileSize) { _ in
                        if timer != nil {
                            restart()
                        }
                    }
                    
                    Picker("Test Intervals", selection: $testInterval) {
                        ForEach(TestInterval.allCases) { testInterval in
                            Text(testInterval.localizedString).tag(testInterval)
                        }
                    }.onChange(of: testInterval) { _ in
                        if timer != nil {
                            restart()
                        }
                    }
                    
                    Button {
                        if let vc = NSStoryboard(name: "Support", bundle: nil).instantiateInitialController() as? NSViewController {
                            NSApp.mainWindow?.contentViewController?.presentAsModalWindow(vc)
                        }
                    } label: {
                        Image(nsImage: NSImage(named: "AppIcon")!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    }.buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                HStack {
                    Button {
                        instantTest()
                        start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }.disabled(startButtonDiabled)
                    
                    Button {
                        stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }.disabled(stopButtonDisabled)
                    
                    Text(String(Int(restTime)))
                        .font(Font.custom("Big Caslon", fixedSize: 18))
                    
                    Text(result)
                        .foregroundColor(resultColor)

                    Spacer()

                    Button {
                        clear()
                    } label: {
                        Label("Clear", systemImage: "clear.fill")
                    }
                }
                
                HStack {
                    Text("Statistics")
                        .font(.title)
                    
                    Spacer()
                    
                    Picker("Method", selection: $stasticalMethod) {
                        ForEach(StatisticalMethod.allCases) { stasticalMethod in
                            Text(stasticalMethod.localizedString).tag(stasticalMethod)
                        }
                    }.frame(width: 200)
                }
                
                let columns:[GridItem] = Array(repeating: .init(.flexible()), count: 5)
                
                LazyVGrid(columns: columns) {
                    ForEach([10], id: \.self) { _ in
                        Text("Last")
                        Text("Good in")
                        Text("Longest DT") // "Longest Disconnection Time"
                        Text("Average DT") // "Average Disconnection Time"
                        Text("Total DT") // "Total Disconnection Time"
                    }
                }
                
                switch stasticalMethod {
                case .frequency:
                    ForEach([10, 30, 50, 100, 500, 1000, 5000], id: \.self) {
                        FrequencyStatisticItemSwiftUIView(frequencyStaticstics: .constant(getFrequencyStaticstics($0)))
                    }
                case .duration:
                    ForEach([1,5,10,15,30,60,180,360,480,720,1440], id: \.self) {
                        DrurationStaticsticsSwiftUIView(durationStatistics: .constant(getDurationStaticstics($0)))
                    }
                }
                
            }
        }.padding()
    }
    
    private func speedTest() async throws {
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
            result = String.localizedStringWithFormat(NSLocalizedString("Good in %dms.", comment: ""), delay)
            resultColor = .green
            add(with: delay)
        } else {
            result = String.localizedStringWithFormat(NSLocalizedString("Failed in %dms.", comment: ""), delay)
            resultColor = .red
            add(with: -delay)
        }
    }
    
    private func getURL() -> URL {
        switch testFileSize {
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
    
    private func start() {
        restTime = TimeInterval(testInterval.rawValue)
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(testInterval.rawValue), repeats: true, block: { _ in
            restTime = TimeInterval(testInterval.rawValue)
            instantTest()
        })
        
        updateCounterDown()
        startButtonDiabled.toggle()
        stopButtonDisabled.toggle()
    }
    
    private func stop() {
        restTime = 0
        timer?.invalidate()
        updateTimer?.invalidate()
        
        startButtonDiabled.toggle()
        stopButtonDisabled.toggle()
    }
    
    private func restart() {
        stop()
        
        instantTest()
        start()
    }
    
    private func instantTest() {
        Task {
            do {
                try await speedTest()
            } catch let error {
                print("\(error)")
                result = "Time out."
                resultColor = .red
                add(with: -1)
            }
        }
    }
    
    private func updateCounterDown() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            restTime -= 1
        }
    }
    
    private func add(with delay:Int) {
        DispatchQueue.main.async {
            let log = DTLog()
            log.interval = testInterval.rawValue
            log.delay = delay
            if delay < 0 {
                log.connected = false
            }
            
            $logs.append(log)
        }
    }
    
    private func clear() {
        DispatchQueue.main.async {
            logs.forEach { $logs.remove($0) }
        }
    }
    
    private func getFrequencyStaticstics(_ count:Int) -> FrequencyStaticstics {
        let min = min(logs.count, count)
        let disconnectedTimePoints = updateDisconnectedTimePoints(in: min)
        
        return FrequencyStaticstics(count: min,
                       max: count,
                       disconnectedTimePoints: disconnectedTimePoints)
    }
    
    private func getDurationStaticstics(_ timeLength:Int) -> DurationStaticstics {
        let disconnectedTimePoints = updateDisconnectedTimePoints(withIn: timeLength)
        
        return DurationStaticstics(timeLength: timeLength,
                                   disconnectedTimePoints: disconnectedTimePoints)
    }
    
    private func updateDisconnectedTimePoints(in count:Int) -> [DisconnectedTimePoint] {
//        let logs = logs.sorted(byKeyPath: "startTime", ascending: false)[0..<count]
        let logs = logs.sorted(byKeyPath: "startTime", ascending: false)[0..<count]

        return updateDisconnectedTimePoints(with:logs)
    }
    
    private func updateDisconnectedTimePoints(withIn timeLength:Int) -> [DisconnectedTimePoint] {
        let now = Date()
        let date = Date(timeInterval: -Double(timeLength * 60), since: now) as NSDate
        let logs = logs.filter(NSPredicate(format: "startTime>%@", date))
        
        return updateDisconnectedTimePoints(with:logs[0..<logs.count])
    }
    
    private func updateDisconnectedTimePoints(with logs:Slice<Results<DTLog>>) -> [DisconnectedTimePoint] {
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
}

enum Flavor: String, CaseIterable, Identifiable {
    case chocolate
    case vanilla
    case strawberry

    var id: String { self.rawValue }
}

enum FileSize:Int, CaseIterable, Identifiable {
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

enum TestInterval:Int, CaseIterable, Identifiable {
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

enum StatisticalMethod:String, CaseIterable, Identifiable {
    var id: String {
        self.rawValue
    }
    
    case frequency
    case duration
    
    var localizedString:String {
        switch self {
        case .frequency:
            return NSLocalizedString("Frequency", comment: "")
        case .duration:
            return NSLocalizedString("Duration", comment: "")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
