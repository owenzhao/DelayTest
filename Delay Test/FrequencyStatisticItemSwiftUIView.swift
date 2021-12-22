//
//  StatisticItemSwiftUIView.swift
//  Realm SwiftUI Sample
//
//  Created by zhaoxin on 2021/12/21.
//

import SwiftUI
import RealmSwift

struct FrequencyStatisticItemSwiftUIView: View {
    @ObservedResults(DTLog.self) var logs
    @Binding var frequencyStaticstics:FrequencyStaticstics
    
    var body: some View {
        let columns:[GridItem] = Array(repeating: .init(.flexible()), count: 5)
        
        LazyVGrid(columns: columns) {
            ForEach([10], id: \.self) { _ in
                Text(String(showCount(frequencyStaticstics)))
                Text(String(format:"%.1f%%", frequencyStaticstics.goodsIn(logs) * 100))
                Text(String(frequencyStaticstics.getLDT()))
                Text(String(frequencyStaticstics.getADT()))
                Text(String(frequencyStaticstics.getTDT()))
            }
        }
    }
    
    private func showCount(_ count:FrequencyStaticstics) -> String {
        if count.count != count.max {
            return "\(count.count)/\(count.max)"
        }
        
        return "\(count.count)"
    }
}

struct StatisticItemSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        FrequencyStatisticItemSwiftUIView(frequencyStaticstics: .constant(FrequencyStaticstics(count: 10,
                                                          max: 10,
                                                          disconnectedTimePoints: [])))
    }
}
