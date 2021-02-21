//
//  ContentView.swift
//  HelloMetal
//
//  Created by Shogo Nobuhara on 2021/02/13.
//

import SwiftUI

struct ContentView: View {
    @State var filter: MetalView.Filter = .original
    
    var body: some View {
        VStack {
            MetalView(filter: $filter)
            HStack {
                Button(action: {
                    self.filter = .sepia
                }, label: {
                    Text("Sepia")
                        .padding()
                })
                
                Button(action: {
                    self.filter = .original
                }, label: {
                    Text("Reset")
                        .padding()
                })
                
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
