//
//  StatisticItemSwiftUIView.swift
//  Realm SwiftUI Sample
//
//  Created by zhaoxin on 2021/12/21.
//

import SwiftUI
import RealmSwift

struct StatisticItemSwiftUIView: View {
    @ObservedResults(DTLog.self) var logs
    @Binding var transit:Transit
    
    var body: some View {
        let columns:[GridItem] = Array(repeating: .init(.flexible()), count: 5)
        
        LazyVGrid(columns: columns) {
            ForEach([10], id: \.self) { _ in
                Text(String(showCount(transit)))
                Text(String(format:"%.1f%%", goodsIn(transit.count) * 100))
                Text(String(getLDT(in: transit.count)))
                Text(String(format:"%.1f", getADT(in: transit.count)))
                Text(String(getTDT(in: transit.count)))
            }
        }
    }
    
    private func showCount(_ count:Transit) -> String {
        if count.count != count.max {
            return "\(count.count)/\(count.max)"
        }
        
        return "\(count.count)"
    }
    
    private func goodsIn(_ count:Int) -> Double {
        let logs = logs.sorted(byKeyPath: "startTime", ascending: false)[0..<count]
        
        if logs.isEmpty {
            return 0
        }
        
        let count = logs.count
        let goodsIn = logs.filter { $0.connected }
        
        return Double(goodsIn.count) / Double(count)
    }
    
    // get max length of disconnected time and average length of disconnected time
    private func getLDT(in count:Int) -> Int { // in seconds
        let LDT = transit.disconnectedTimePoints.max(by: { $0.timeLength < $1.timeLength })?.timeLength ?? 0
        
        return LDT
    }
    
    private func getADT(in count:Int) -> Double {
        let ADT:Double = {
            if transit.disconnectedTimePoints.isEmpty {
                return 0
            } else {
                return transit.disconnectedTimePoints.reduce(0.0) { partialResult, disconnectedTimePoint in
                    partialResult + Double(disconnectedTimePoint.timeLength)
                } / Double(transit.disconnectedTimePoints.count)
            }
        }()
        
        return ADT
    }
    
    private func getTDT(in count:Int) -> Int {
        let TDT = transit.disconnectedTimePoints.reduce(0) { partialResult, disconnectedTimePoint in
            partialResult + disconnectedTimePoint.timeLength
        }
        
        return TDT
    }
}

struct StatisticItemSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticItemSwiftUIView(transit: .constant(Transit(count: 10,
                                                          max: 10,
                                                          disconnectedTimePoints: [])))
    }
}
