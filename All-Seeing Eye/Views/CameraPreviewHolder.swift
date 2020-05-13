//
//  CameraPreviewHolder.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 13/05/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import SwiftUI

struct CameraPreviewHolder: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<CameraPreviewHolder>) -> CameraView {
        CameraView()
    }

    func updateUIView(_ uiView: CameraView, context: UIViewRepresentableContext<CameraPreviewHolder>) {
    }

    typealias UIViewType = CameraView
}
