//
//  DurationStaticsticsSwiftUIView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/22.
//

import SwiftUI
import RealmSwift

struct DrurationStaticsticsSwiftUIView: View {
    @ObservedResults(DTLog.self) var logs
    @Binding var durationStatistics:DurationStaticstics
    
    var body: some View {
        let columns:[GridItem] = Array(repeating: .init(.flexible()), count: 5)
        
        LazyVGrid(columns: columns) {
            ForEach([10], id: \.self) { _ in
                Text(String(showDate(durationStatistics)))
                Text(String(format:"%.1f%%", durationStatistics.goodsIn(logs) * 100))
                Text(String(durationStatistics.getLDT()))
                Text(String(durationStatistics.getADT()))
                Text(String(durationStatistics.getTDT()))
            }
        }
    }
    
    private func showDate(_ durationStatistics:DurationStaticstics) -> String {
        if durationStatistics.timeLength < 60 {
            return String(format: NSLocalizedString("%d minutes", comment: ""), durationStatistics.timeLength)
        }
        
        let hours = durationStatistics.timeLength / 60
        return String(format: NSLocalizedString("%d hours", comment: ""), hours)
    }
}

struct DrurationStaticsticsSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DrurationStaticsticsSwiftUIView(durationStatistics: .constant(DurationStaticstics(timeLength: 1,
                                                                                          disconnectedTimePoints: [])))
    }
}
