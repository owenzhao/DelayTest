//
//  ContentView.swift
//  Delay Test
//
//  Created by zhaoxin on 2021/12/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment:.leading, spacing: 2) {
            Text("测试文件")
            Text("10KB")
            Text("100KB")
            
            Spacer()
            
            Group {
                Text("测试频率")
                Text("10秒")
                Text("30秒")
                Text("1分")
                Text("5分")
                Text("10分")
            }
            
            Spacer()
            
            Text("10分")
        }.padding()
            .onAppear {
//                let stringIn10KB = createString(at: 10 * 1024)
//                let savePanel = NSSavePanel()
//                savePanel.begin { response in
//                    if let url = savePanel.url {
//                        try! stringIn10KB.write(to: url, atomically: true, encoding: .utf8)
//                    }
//                }
                Task {
                    try await speedTest()
                }
            }
        
    }
    
    private func createString(at size:Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<size).map{ _ in letters.randomElement()! })
    }
    
    private func speedTest() async throws {
        let url = URL(string: "https://parussoft.com//speed_test/10K.txt")!
        let startTime = ProcessInfo.processInfo.systemUptime
        let (targetUrl, response) = try await URLSession.shared.download(from: url)
        let endTime = ProcessInfo.processInfo.systemUptime
        let delay = Int((endTime - startTime) * 1000)
        
        if (response as! HTTPURLResponse).statusCode == 200 {
            print("Good in \(delay)ms")
        } else {
            print("Failed in \(delay)ms")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
