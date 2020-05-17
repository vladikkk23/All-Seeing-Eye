//
//  CameraView.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 13/05/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import SwiftUI
import AVFoundation
import Vision

// Need UIViewControllerRepresentable to show any UIViewController in SwiftUI
struct CameraView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let controller = CameraViewController()
        return controller
    }
    
    
    func updateUIViewController(_ uiViewController: CameraView.UIViewControllerType, context: UIViewControllerRepresentableContext<CameraView>) { }
}

// My custom class which inits an AVSession for the live preview
class CameraViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoOutputQueue = DispatchQueue(label: "Video_Output")
    
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    
    // Initializing Model
    private let objectDetector = Object_Detector(modelWithName: "YOLOv3")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCamera()
        self.session.startRunning()
    }
    
    func loadCamera() {
        
        guard let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else { return }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("NO CAMERA DETECTED")
            return
        }
        
        // Begin session config
        self.session.beginConfiguration()
        self.session.sessionPreset = .vga640x480
        
        guard self.session.canAddInput(videoDeviceInput) else {
            NSLog("Could not add video device input to the session")
            self.session.commitConfiguration()
            return
        }
        // Add video input
        self.session.addInput(videoDeviceInput)
        
        if session.canAddOutput(self.videoDataOutput) {
            // Add a video data output
            self.session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
        } else {
            NSLog("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        guard let captureConnection = videoDataOutput.connection(with: .video) else { return }
        
        // Always process the frames
        captureConnection.isEnabled = true
        
        do {
            try videoDevice.lockForConfiguration()
            
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice.activeFormat.formatDescription))
            // Read frame dimensions
            self.bufferSize.width = CGFloat(dimensions.width)
            self.bufferSize.height = CGFloat(dimensions.height)
            
            videoDevice.unlockForConfiguration()
        } catch {
            NSLog(error.localizedDescription)
        }
        
        // Save session config
        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = view.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Get buffer with image data
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            NSLog("Error: Failed to get image buffer->\(#line)")
            
            return
        }
        
        // Get device orientation
        let deviceOrientation = self.exifOrientationFromDeviceOrientation()
        
        // Create an image request handler
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: deviceOrientation, options: [:])
        
        do {
            try requestHandler.perform(self.objectDetector.requests)
        } catch {
            NSLog("Error: Unable to perform requests")
        }
    }
    
    // Specify device orientation
    private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
