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

struct CameraView : UIViewControllerRepresentable {
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let controller = CameraViewController()
        return controller
    }
    
    
    func updateUIViewController(_ uiViewController: CameraView.UIViewControllerType, context: UIViewControllerRepresentableContext<CameraView>) { }
}

class CameraViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    private var detectionOverlay: CALayer! = nil
    
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoOutputQueue = DispatchQueue(label: "Video_Output")
    
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    
    // Initializing Model
    private let objectDetector = Object_Detector(modelWithName: "YOLOv3")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCamera()
        setupLayers()
        updateLayerGeometry()
        
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
        self.session.sessionPreset = .hd1920x1080
        
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
            
            // Adding bounding box
            let boundingBox = self.objectDetector.boundingBox
            let objectType = self.objectDetector.objectType
            
            if !boundingBox.isEmpty && objectType != nil {
                DispatchQueue.main.async {
                    CATransaction.begin()
                    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                    self.detectionOverlay.sublayers = nil
                    
                    let objectBounds = VNImageRectForNormalizedRect(boundingBox, Int(self.bufferSize.width), Int(self.bufferSize.height))
                    
                    let shapeLayer = self.createBoundingBox(withBounds: objectBounds)
                    
                    let textLayer = self.createTextBox(withBounds: objectBounds)
                    
                    shapeLayer.addSublayer(textLayer)
                    self.detectionOverlay.addSublayer(shapeLayer)
                    
                    self.updateLayerGeometry()
                    CATransaction.commit()
                }
            }
        } catch {
            NSLog("Error: Unable to perform requests")
        }
    }
    
    func createBoundingBox(withBounds bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        let borderColor = self.objectDetector.objectType?.getColor()
        
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.borderColor = borderColor
        shapeLayer.borderWidth = 2.5
        shapeLayer.cornerRadius = 5.0
        
        return shapeLayer
    }
    
    func createTextBox(withBounds bounds: CGRect) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(self.objectDetector.firstObservation.labels[0].identifier)"))
        let backgroundColor = self.objectDetector.objectType?.getColor()
        let largeFont = UIFont(name: "AvenirNext-Medium", size: 40.0)!
        
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont, NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange(location: 0, length: self.objectDetector.firstObservation.labels[0].identifier.count))
        
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height, height: 50)
        textLayer.position = CGPoint(x: bounds.minX - 25, y: bounds.maxY)
        textLayer.foregroundColor = CGColor(srgbRed: 255, green: 255, blue: 255, alpha: 1)
        textLayer.backgroundColor = backgroundColor
        textLayer.contentsScale = 2.0
        textLayer.cornerRadius = 5.0
        
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        return textLayer
    }
    
    func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0, y: 0.0, width: bufferSize.width, height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // Rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        
        // Center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
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
