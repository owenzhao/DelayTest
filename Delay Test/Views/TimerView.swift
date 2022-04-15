//
//  TimerView.swift
//  Internet Helper
//
//  Created by zhaoxin on 2022/4/15.
//

import SwiftUI
import SpeedTestServiceNotification

struct TimerView: View {
    @Binding var isShown:Bool
    @Binding var service:SpeedTestService
    @Binding var testInterval:TestInterval
    
    @State private var restTime = 0
    @State private var countdownTimer:Timer? = nil
    
    private let newLogPublisher = NotificationCenter.default.publisher(for: Notification.Name.dtLogNewLog)
    private let stopTimerPublisher = NotificationCenter.default.publisher(for: SpeedTestServiceNotification.stop)
    
    var body: some View {
        Text(String(restTime))
            .font(Font.custom("Big Caslon", fixedSize: 18))
            .onReceive(newLogPublisher) { _ in
                startCountdownTimer()
            }
            .onReceive(stopTimerPublisher) { _ in
                stopCountdownTimer()
            }
    }
    
    private func startCountdownTimer() {
        if countdownTimer != nil {
            stopCountdownTimer()
        }
        
        restTime = testInterval.rawValue
        
        let updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            if restTime == 0 {
                stopCountdownTimer()
                
                Task {
                    try await service.restart()
                }
            } else if isShown {
                restTime -= 1
            }
        }
        
        countdownTimer = updateTimer
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        restTime = 0
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(isShown: .constant(false),
                  service: .constant(SpeedTestService()),
                  testInterval: .constant(TestInterval.fiveMinutes))
    }
}
