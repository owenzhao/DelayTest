//
//  StatisticItemSwiftUIView.swift
//  Realm SwiftUI Sample
//
//  Created by zhaoxin on 2021/12/21.
//

import SwiftUI
import RealmSwift

struct FrequencyStatisticItemSwiftUIView: View {
    @State var title = ""
    @State var goodInString = ""
    @State var longestDisconnectedTimeString = ""
    @State var longestAverageDisconnectedTimeString = ""
    @State var totalDisconnectedTimeString = ""
    
    var body: some View {
        let columns:[GridItem] = Array(repeating: .init(.flexible()), count: 5)
        
        LazyVGrid(columns: columns) {
            Text(title)
            Text(goodInString)
            Text(longestDisconnectedTimeString)
            Text(longestAverageDisconnectedTimeString)
            Text(totalDisconnectedTimeString)
        }
    }
}

struct StatisticItemSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        FrequencyStatisticItemSwiftUIView()
    }
}
