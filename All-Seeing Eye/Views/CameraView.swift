//
//  CameraView.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 13/05/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import SwiftUI
import AVFoundation

class CameraView: UIView {
    private var captureSession: AVCaptureSession?

    init() {
        super.init(frame: .zero)

        var allowedAccess = false
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()

        if !allowedAccess {
            NSLog("NO ACCESS TO CAMERA")
            return
        }

        // setup session
        let session = AVCaptureSession()
        session.beginConfiguration()

        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
            for: .video, position: .unspecified) //alternate AVCaptureDevice.default(for: .video)
        guard videoDevice != nil, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(videoDeviceInput) else {
            NSLog("NO CAMERA DETECTED")
            return
        }
        session.addInput(videoDeviceInput)
        session.commitConfiguration()
        self.captureSession = session
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if nil != self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspect
            self.captureSession?.startRunning()
        } else {
            self.captureSession?.stopRunning()
        }
    }
}
