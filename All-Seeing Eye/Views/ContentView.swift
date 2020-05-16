//
//  ContentView.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 08/04/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State var isShowingCamera = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: CameraView(), isActive: self.$isShowingCamera) {
                    EmptyView()
                }
                
                Button(action: {
                    self.isShowingCamera.toggle()
                }) {
                    Text("Enable Object Detection")
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
