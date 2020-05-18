//
//  Object_Detector.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 16/05/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class Object_Detector {
    
    // MARK: Properties
    var requests = [VNRequest]()
    
    var boundingBox = CGRect()
    var objectType: ObservationTypeEnum?
    var firstObservation = VNRecognizedObjectObservation()
    
    init(modelWithName modelName: String) {
        self.setupModel(withFilename: modelName)
    }
    
    // MARK: Methods
    private func setupModel(withFilename modelName: String) {
        // Get model URL
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            NSLog("Error: Unable to find model with name\(modelName), in \(Bundle.main.bundlePath)")
            
            return
        }
        
        // Create desired model
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
            NSLog("Error: Failed to create model->line:\(#line)")
            
            return
        }
        
        // Perform a request using ML Model
        let objectRecognizerRequests = VNCoreMLRequest(model: model) { (request, err) in
            if let error = err {
                NSLog("Error: \(error.localizedDescription)")
                
                return
            }
            
            // Get observation results
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                NSLog("Error: Failed to extract request results as [VNRecognizedObjectObservation]")
                
                return
            }
            
            // Get first observation result (one with the greatest confidence)
            guard let firstResult = results.first else { return }
            
            self.firstObservation = firstResult
            self.objectType = ObservationTypeEnum(fromRawValue: firstResult.labels.first!.identifier)
            self.boundingBox = firstResult.boundingBox
        }
        
        // Save requests
        self.requests = [objectRecognizerRequests]
    }
}
