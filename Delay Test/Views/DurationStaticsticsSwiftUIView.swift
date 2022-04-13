//
//  DurationStaticsticsSwiftUIView.swift
//  Internet Helper
//
//  Created by zhaoxin on 2021/12/22.
//

import SwiftUI
import RealmSwift

struct DrurationStaticsticsSwiftUIView: View {
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

struct DrurationStaticsticsSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DrurationStaticsticsSwiftUIView()
    }
}
