//
//  ContentView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/20.
//

import SwiftUI
import RealmSwift
import Defaults

struct ContentView: View {
    @Binding var service:SpeedTestService
    @ObservedResults(DTLog.self) var logs
    @State private var window:NSWindow? = nil
    private let windowDelegate = WindowDelegate()
    
    @Default(.startFromLauncher) private var startFromLauncher
    @Default(.testFileSize) private var testFileSize
    @Default(.testInterval) private var testInterval
    @Default(.startButtonDisabled) private var startButtonDisabled
    @Default(.stopButtonDisabled) private var stopButtonDisabled
    @State private var stasticalMethod = StatisticalMethod.frequency
    @State private var restTime = 0
    @State private var result = DTResult()
    
    @State private var isShown = true
    
    @Default(.goodTextColor) private var goodTextColor
    @Default(.failTextColor) private var failTextColor
    
    private let newLogPublisher = NotificationCenter.default.publisher(for: DTLog.newLog, object: nil)
    private let restTimePublisher = NotificationCenter.default.publisher(for: SpeedTestService.restTimeDidChanged, object: nil)
    
    @State private var windowOnTop = false
    
    var body: some View {
        ScrollView {
            HStack {
                Picker("Test File", selection: $testFileSize) {
                    ForEach(FileSize.allCases) { fileSize in
                        Text(fileSize.localizedString).tag(fileSize)
                    }
                }.onChange(of: testFileSize) { _ in
                    if startButtonDisabled {
                        Task {
                            try await service.restart()
                        }
                    }
                }
                
                Picker("Test Intervals", selection: $testInterval) {
                    ForEach(TestInterval.allCases) { testInterval in
                        Text(testInterval.localizedString).tag(testInterval)
                    }
                }.onChange(of: testInterval) { _ in
                    if startButtonDisabled {
                        Task {
                            try await service.restart()
                        }
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
            HStack {
                Button {
                    startButtonDisabled.toggle()
                    stopButtonDisabled.toggle()
                    NotificationCenter.default.post(name: SpeedTestService.start, object: self)
                    
                } label: {
                    Label("Start", systemImage: "play.fill")
                }.disabled(startButtonDisabled)
                
                Button {
                    startButtonDisabled.toggle()
                    stopButtonDisabled.toggle()
                    NotificationCenter.default.post(name: SpeedTestService.stop, object: self)
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }.disabled(stopButtonDisabled)
                
                Text(String(restTime))
                    .font(Font.custom("Big Caslon", fixedSize: 18))
                
                Text(result.string)
                    .foregroundColor(.green)
                
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
        }.padding()
            .onReceive(newLogPublisher) { notification in
                if let log = notification.userInfo?["log"] as? DTLog {
                    self.result = getResult(from: log)
                }
            }
            .onReceive(restTimePublisher) { notification in
                if isShown, let restTime = notification.userInfo?["restTime"] as? Int {
                    self.restTime = restTime
                }
            }
            .onAppear {
                DispatchQueue.main.async { [self] in
                    if let window = NSApp.keyWindow {
                        self.window = window
                        window.delegate = windowDelegate
                        
                        if startFromLauncher {
                            startFromLauncher.toggle()
                            NSApp.hide(self)
                        }
                    }
                }
                
                // MARK: Workaround for push result not sync
                if startButtonDisabled {
                    Task {
                        try await service.restart()
                    }
                }
                
                isShown = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification, object: window), perform: { notification in
                isShown = false
            })
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didDeminiaturizeNotification, object: window), perform: { notification in
                isShown = true
            })
            
            .toolbar {
                Button {
                    windowOnTop.toggle()
                    
                    if let window = NSApp.keyWindow {
                        window.level = (windowOnTop ? .floating : .normal)
                    }
                } label: {
                    if windowOnTop {
                        Image(systemName: "macwindow.on.rectangle")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "macwindow")
                    }
                    
                }
            }
    }
    
    private func getResult(from log:DTLog) -> DTResult {
        var result = DTResult()
        
        if log.connected {
            result.string = String.localizedStringWithFormat(NSLocalizedString("Good in %dms.", comment: ""), log.delay)
            result.color = goodTextColor.color
        } else {
            if log.delay == -1 {
                result.string = NSLocalizedString("Connection timed out.", comment: "")
            } else {
                result.string = String.localizedStringWithFormat(NSLocalizedString("Failed in %dms.", comment: ""), -log.delay)
            }
            
            result.color = failTextColor.color
        }
        
        return result
    }
    
    private func clear() {
        service.removeDatabase()
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
        ContentView(service: .constant(SpeedTestService()))
    }
}
