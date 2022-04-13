//
//  ContentView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/20.
//

import SwiftUI
import RealmSwift
import Defaults
import Chinese24Jieqi
import MyHost
import SpeedTestServiceNotification
import SwiftUIWindowBinder

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    private var defaultColor:Color {
        return colorScheme == .dark ? .white : .black
    }
    
    @Binding var service:SpeedTestService
    private let model = Model()
    
    @State private var window:NSWindow? = nil
    private let windowDelegate = WindowDelegate(tag: .main)
    
    @Default(.startFromLauncher) private var startFromLauncher
    @Default(.testFileSize) private var testFileSize
    @Default(.testInterval) private var testInterval
    @Default(.startButtonDisabled) private var startButtonDisabled
    @Default(.stopButtonDisabled) private var stopButtonDisabled
    
    @State private var stasticalMethod = StatisticalMethod.duration
    @ObservedObject private var countdownTimerModel = CountdownModel()
    @State private var countdownTimer:Timer? = nil
    private let runLoop = RunLoop.current
    
    @State private var result = DTResult()
    
    @State private var isShown = true
    
    private let newLogPublisher = NotificationCenter.default.publisher(for: Notification.Name.dtLogNewLog, object: nil)
    private let runningTestPublisher = NotificationCenter.default.publisher(for: Notification.Name.backgroundRunningTest)
    
    @State private var windowOnTop = false
    
    @State var enthernet:NetworkLink
    @State var wifi:NetworkLink
    @State var internetIPV4:String
    @State var internetIPV6:String
    
    private let enthernetUpdatePublisher = NotificationCenter.default.publisher(for: MyHost.EnthernetUpdate, object: nil)
    private let wifiUpdatePublisher = NotificationCenter.default.publisher(for: MyHost.WifiUpdate, object: nil)
    private let internetIPV4Publisher = NotificationCenter.default.publisher(for: MyHost.InternetIPV4Update, object: nil)
    private let internetIPV6Publisher = NotificationCenter.default.publisher(for: MyHost.InternetIPV6Update, object: nil)
    
    var body: some View {
        WindowBinder(window: $window) {
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
                            .frame(width: IHImageSize.appImage.width!, height: IHImageSize.appImage.height!)
                    }.buttonStyle(PlainButtonStyle())
                }
                
                HStack {
                    Button {
                        startButtonDisabled.toggle()
                        stopButtonDisabled.toggle()
                        NotificationCenter.default.post(name: SpeedTestServiceNotification.start, object: self)
                        
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }.disabled(startButtonDisabled)
                    
                    Button {
                        startButtonDisabled.toggle()
                        stopButtonDisabled.toggle()
                        NotificationCenter.default.post(name: SpeedTestServiceNotification.stop, object: self)
                        
                        stopCountdownTimer()
                        result = DTResult(state: .stop)
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }.disabled(stopButtonDisabled)
                    
                    Text(String(countdownTimerModel.restTime))
                        .font(Font.custom("Big Caslon", fixedSize: 18))

                    result.getText()
                    
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
                    }.frame(width: IHViewSize.picker.width)
                }
                
                let columns:[GridItem] = Array(repeating: .init(.flexible()), count: 5)
                
                LazyVGrid(columns: columns) {
                    Text("Last")
                    Text("Good in")
                    Text("Longest DT") // "Longest Disconnected Time"
                    Text("Average DT") // "Average Disconnected Time"
                    Text("Total DT") // "Total Disconnected Time"
                }
                
                switch stasticalMethod {
                case .frequency:
                    ForEach([10, 30, 50, 100, 500, 1000, 5000].map { getFrequencyStaticstics($0) }) { frequencyStaticstics in
                        FrequencyStatisticItemSwiftUIView(title: String(showCount(frequencyStaticstics)),
                                                          goodInString: String(format:"%.1f%%", frequencyStaticstics.goodsIn() * 100),
                                                          longestDisconnectedTimeString: String(frequencyStaticstics.getLDT()),
                                                          longestAverageDisconnectedTimeString: String(frequencyStaticstics.getADT()),
                                                          totalDisconnectedTimeString: String(frequencyStaticstics.getTDT()))
                    }
                case .duration:
                    ForEach([1,5,10,15,30,60,180,360,480,720,1440].map { getDurationStaticstics($0) }) { durationStatistics in
                        
//                        TODO: - Workaround as the view is not auto updated as it should.
                        if model.logs.isEmpty {
                            DrurationStaticsticsSwiftUIView(title: String(showDate(durationStatistics)),
                                                            goodInString: "0.0%",
                                                            longestDisconnectedTimeString: "0",
                                                            longestAverageDisconnectedTimeString: "0",
                                                            totalDisconnectedTimeString: "0")
                        } else {
                            DrurationStaticsticsSwiftUIView(title: String(showDate(durationStatistics)),
                                                            goodInString: String(format:"%.1f%%", durationStatistics.goodsIn() * 100),
                                                            longestDisconnectedTimeString: String(durationStatistics.getLDT()),
                                                            longestAverageDisconnectedTimeString: String(durationStatistics.getADT()),
                                                            totalDisconnectedTimeString: String(durationStatistics.getTDT()))
                        }
                        
                    }
                }
                
                Spacer(minLength: 40)

                HStack(alignment: .top, spacing: 20) {
                    Text(getDateString())
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: -15) {
                        Text("Wired Network")
                            .foregroundColor(.green)
                        Text(show(networkLink:enthernet))
                            .foregroundColor(.blue)
                            .onReceive(enthernetUpdatePublisher) { notification in
                                if let enthernet = notification.object as? NetworkLink {
                                    self.enthernet = enthernet
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: -15) {
                        Text("Wifi Network")
                            .foregroundColor(.green)
                        Text(show(networkLink:wifi))
                            .foregroundColor(.blue)
                            .onReceive(wifiUpdatePublisher) { notification in
                                if let wifi = notification.object as? NetworkLink {
                                    self.wifi = wifi
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Internet")
                            .foregroundColor(.green)
                        Text("IPV4: \(showIP(type: .ipv4))")
                            .foregroundColor(.blue)
                            .onReceive(internetIPV4Publisher) { notification in
                                if let internet = notification.object as? String {
                                    internetIPV4 = internet
                                }
                            }
                        Text("IPV6: \(showIP(type:.ipv6))")
                            .foregroundColor(.blue)
                            .onReceive(internetIPV4Publisher) { notification in
                                if let internet = notification.object as? String {
                                    internetIPV6 = internet
                                }
                            }
                    }
                }
                .padding()
                .font(.subheadline)
            }
            .padding()
            .frame(minWidth: IHWindowSize.mainWindow.minWidth!,
                   idealHeight: IHWindowSize.mainWindow.idealHeight!)
            .onReceive(newLogPublisher) { notification in
                if let log = notification.userInfo?["log"] as? DTLog {
                    model.save(log)
                    self.result = DTResult(state: .result(log: log))
                    
                    startCountdownTimer()
                }
            }
            .onReceive(runningTestPublisher, perform: { _ in
                if isShown {
                    result = DTResult(state: .testing)
                }
            })
            .onAppear {
                if startFromLauncher {
                    startFromLauncher.toggle()
                    NSApp.hide(self)
                }
                
                isShown = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didHideNotification, object: nil), perform: { _ in
                isShown = false
            })
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didUnhideNotification, object: nil), perform: { _ in
                isShown = true
            })
            .navigationTitle(NSLocalizedString("Delay Test", comment: ""))
//        MARK: - Toolbar
            .toolbar {
                HStack {
                    Spacer()
                    
                    Button {
                        windowOnTop.toggle()
                        
                        if let window = NSApp.keyWindow {
                            window.level = (windowOnTop ? .floating : .normal)
                        }
                    } label: {
                        if windowOnTop {
                            Image(systemName: "macwindow.on.rectangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "macwindow")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }.help(Text("Window On Top"))
                }
            }
        }
        .onChange(of: window) { newValue in
            if let window = newValue {
                window.delegate = windowDelegate
                window.isReleasedWhenClosed = true
                
                if NSApp.orderedWindows.filter({
                    if let windowDelegate = $0.delegate as? WindowDelegate {
                        return windowDelegate.tag == .main
                    }
                    
                    return false
                }).count > 1 { // another main view is shown
                    MyHost.shared.updateHostNotifications()
                }
            }
        }
    }
    
    private func getDateString() -> String {
        let jieqi = Jieqi()
        
        if let log = model.logs.first {
            return jieqi.xinwenlianboDateString(log.startTime)
        }
        
        return jieqi.xinwenlianboDateString(Date())
    }
    
    private func clear() {
        model.clear()
    }
    
    private func getFrequencyStaticstics(_ count:Int) -> FrequencyStaticsticsToNow {
        return FrequencyStaticsticsToNow(count: count, logs: model.logs)
    }
    
    private func getDurationStaticstics(_ timeLength:Int) -> DurationStaticsticsToNow {
        return DurationStaticsticsToNow(timeLength: timeLength, logs: model.logs)
    }
    
    private func showDate(_ durationStatistics:DurationStaticsticsToNow) -> String {
        if durationStatistics.timeLength < 60 {
            return String(format: NSLocalizedString("%d minutes", comment: ""), durationStatistics.timeLength)
        }
        
        let hours = durationStatistics.timeLength / 60
        return String(format: NSLocalizedString("%d hours", comment: ""), hours)
    }
    
    private func showCount(_ count:FrequencyStaticsticsToNow) -> String {
        if count.count != count.max {
            return "\(count.count)/\(count.max)"
        }
        
        return "\(count.count)"
    }
    
    private func updateDisconnectedTimePoints(in count:Int) -> [DisconnectedTimePoint] {
        let logs = model.logs[0..<count]

        return updateDisconnectedTimePoints(with:logs)
    }
    
    private func updateDisconnectedTimePoints(withIn timeLength:Int) -> [DisconnectedTimePoint] {
        let now = Date()
        let date = Date(timeInterval: -Double(timeLength * 60), since: now) as NSDate
        let logs = model.logs.filter(NSPredicate(format: "startTime>%@", date))
        
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
    
    private func show(networkLink:NetworkLink) -> String {
        var result = ""
        
        result += "\nMac: \(networkLink.MAC)"
        
        if let ipv4 = networkLink.ipv4 {
            result += "\nIPV4: \(ipv4)"
        } else {
            result += NSLocalizedString("\nIPV4: Inactive", comment: "")
        }
        
        if let ipv6 = networkLink.ipv6 {
            result += "\nIPV6: \(ipv6)"
        } else {
            result += NSLocalizedString("\nIPV6: Inactive", comment: "")
        }
        
        return result
    }
    
    private func showIP(type:IPType) -> String {
        switch type {
        case .ipv4:
            return internetIPV4
        case .ipv6:
            return internetIPV6
        }
    }
    
    private func startCountdownTimer() {
        if countdownTimer != nil {
            stopCountdownTimer()
        }
        
        countdownTimerModel.restTime = testInterval.rawValue
        
        let updateTimer = Timer(timeInterval: 1, repeats: true) { [self] _ in
            if countdownTimerModel.restTime == 0 {
                stopCountdownTimer()
                
                Task {
                    try await service.restart()
                }
            } else if isShown {
                countdownTimerModel.restTime -= 1
            }
        }
        
        runLoop.add(updateTimer, forMode: .common)
        countdownTimer = updateTimer
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        countdownTimerModel.restTime = 0
    }
}

enum StatisticalMethod:String, CaseIterable, Identifiable, DefaultsSerializable {
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
    
    var intervalString:String {
        switch self {
        case .frequency:
            return NSLocalizedString("in times", comment: "")
        case .duration:
            return NSLocalizedString("in minutes", comment: "")
        }
    }
    
    var range:ClosedRange<Int> {
        switch self {
        case .frequency:
            return 1...100_000
        case .duration:
            return 1...360
        }
    }
    
    var initialInverval:Int {
        switch self {
        case .frequency:
            return 10
        case .duration:
            return 1
        }
    }
    
    enum FrequemcyStep:Int, CaseIterable, Identifiable, DefaultsSerializable {
        var id : Self { return self }
        
        case ten = 10
        case fifty = 50
        case hundred = 100
        case thousand = 1000
    }
    
    enum DurationStep {
        
    }
}

class CountdownModel:ObservableObject {
    @Published var restTime = 0
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(service: .constant(SpeedTestService()),
                    enthernet: NetworkLink(MAC: ""),
                    wifi: NetworkLink(MAC: ""),
                    internetIPV4: "",
                    internetIPV6: "")
    }
}
