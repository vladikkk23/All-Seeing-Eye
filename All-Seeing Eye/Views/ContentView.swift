//
//  ContentView.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 08/04/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            CameraPreviewHolder()
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}
