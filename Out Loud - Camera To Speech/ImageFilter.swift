//
//  ImageFilter.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 19/10/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//
// Applies filters to images it receives

import UIKit
import Vision // use the Vision Framework

class ImageFilter: NSObject {
    let controller: ViewController
    
    init(viewController: ViewController){
        self.controller = viewController
        super.init()
    }
    
    func detectTextAreas(_ inputImage: UIImage) -> [UIImage]? {
        // runs text detection algorithms and returns a collection of UIImage's to apply OCR. Return nil if no text has been found.
        var outputImagesStorage = [UIImage]()
        guard let cgImage = inputImage.cgImage else {print("Unable to convert image to CGImage"); return nil}// generate CGImage from the UIImage
        guard let ciImage = CIImage.init(image: inputImage, options: [:]) else {print("Unable to convert image to CIImage"); return nil}// generate CIImage from the UIImage
        let inputImageOrientation = inputImage.imageOrientation.getCGOrientationFromUIImage()
        
        let textDetectionRequest = VNDetectTextRectanglesRequest(completionHandler: {(req, error) in
            if let error = error {
                print("Detection failed. Error: \(error)")
                return
            }
            req.results?.forEach({(res) in
                guard let observation = res as? VNTextObservation else {print("No observation detected.");return}
                let boundingBox = observation.boundingBox
                print("Bounding box: ", boundingBox)
                
                // Use the bounding box to determine where in the view frame to draw a rectangle corresponding to the detection.
                let conversionRatio = self.controller.view.frame.width / inputImage.size.width
                let scaledHeight = conversionRatio * inputImage.size.height
                let x = self.controller.view.frame.width * boundingBox.origin.x // + imageView.frame.origin.x
                let width = self.controller.view.frame.width * boundingBox.width
                let height = scaledHeight * boundingBox.height
                let y = scaledHeight * (1-boundingBox.origin.y) - height // + imageView.frame.origin.y

                // for now I will just draw the rectangles.
                let redBox = UIView()
                redBox.backgroundColor = .red
                redBox.alpha = 0.3
                redBox.frame = CGRect(x: x, y: y, width: width, height: height)
                self.controller.view.addSubview(redBox)
                
            })
        })
        //        print("Default state of reportCharacterBoxes: \(textDetectionRequest.reportCharacterBoxes)") // Evaluated to false
        //        textDetectionRequest.reportCharacterBoxes = true
        let textDetectionHandler = VNImageRequestHandler(cgImage: cgImage, orientation: inputImageOrientation, options: [:])
        
        DispatchQueue.global(qos: .background).async {
            do {
                try textDetectionHandler.perform([textDetectionRequest])
            } catch {
                print(error)
            }
        }
        
//        let imageSize = ciImage.extent.size
//        for observation in textDetectionRequest.results as! [VNTextObservation] { // detects areas of text. Inherits from VNDetectedObjectObservation so it has a bounding box.
//            print(observation)
//
//            //Verify that detected rectangle is valid
//            let boundingBox = observation.boundingBox.scaled(to: imageSize)
//            guard ciImage.extent.contains(boundingBox) else {print("Invalid rectanble detected.");return nil}
        
//            let textBox = UIView()
//            textBox.frame = boundingBox
//            textBox.backgroundColor = .blue
//            textBox.alpha = 0.2
//
            
            
            // determine rectangle edges
//            let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
//            let topRight = detectedRectangle.topRight.scaled(to: imageSize)
//            let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
//            let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
            
            
            
            
            
            
            
//            guard let characterBoxes = observation.characterBoxes else {print("Error detecting character boxes."); return nil} // retrieves all boxes that contain a character
//            for detectedRectangle in characterBoxes { // iterates thru each rectangle around a character
//                let imageSize = ciImage.extent.size
//
//                // Verify detected rectangle is valid.
//                let boundingBox = observation.boundingBox.scaled(to: imageSize)
//                guard ciImage.extent.contains(boundingBox) else { print("invalid rectangle detected."); return nil}
//
//                // Rectify the detected image and reduce it to inverted grayscale for applying model.
//                let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
//                let topRight = detectedRectangle.topRight.scaled(to: imageSize)
//                let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
//                let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
//                let correctedImage = ciImage
//                    .cropped(to: boundingBox)
//                    .applyingFilter("CIPerspectiveCorrection", parameters: [
//                        "inputTopLeft": CIVector(cgPoint: topLeft),
//                        "inputTopRight": CIVector(cgPoint: topRight),
//                        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
//                        "inputBottomRight": CIVector(cgPoint: bottomRight)
//                        ])
//                outputImagesStorage.append(UIImage(ciImage: correctedImage, scale: 1.0, orientation: inputImage.imageOrientation))
//            }
//        }
//        return outputImagesStorage
        return []
    }
}
