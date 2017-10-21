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
    override init(){
        super.init()
    }
    func detectTextAreas(_ inputImage: UIImage) -> [UIImage]? {
        // runs text detection algorithms and returns a processed UIImage. Return nil if no text has been found.
        var outputImagesStorage = [UIImage]()
        let textDetectionRequest = VNDetectTextRectanglesRequest()
//        print("Default state of reportCharacterBoxes: \(textDetectionRequest.reportCharacterBoxes)") // Evaluated to false
        textDetectionRequest.reportCharacterBoxes = true
        guard let cgImage = inputImage.cgImage else {print("Unable to convert image to CGImage"); return nil}// generate CGImage from the UIImage
        guard let ciImage = CIImage.init(image: inputImage, options: [:]) else {print("Unable to convert image to CIImage"); return nil}// generate CIImage from the UIImage
        let inputImageOrientation = inputImage.imageOrientation.getCGOrientationFromUIImage()
        let textDetectionHandler = VNImageRequestHandler(cgImage: cgImage, orientation: inputImageOrientation, options: [:])
        
        do {
            try textDetectionHandler.perform([textDetectionRequest])
        } catch {
            print(error)
        }
        for observation in textDetectionRequest.results as! [VNTextObservation] { // detects areas of text
            guard let characterBoxes = observation.characterBoxes else {print("Error detecting character boxes."); return nil} // retrieves all boxes that contain a character
            for detectedRectangle in characterBoxes { // iterates thru each rectangle around a character
                let imageSize = ciImage.extent.size
                
                // Verify detected rectangle is valid.
                let boundingBox = observation.boundingBox.scaled(to: imageSize)
                guard ciImage.extent.contains(boundingBox) else { print("invalid rectangle detected."); return nil}
                
                // Rectify the detected image and reduce it to inverted grayscale for applying model.
                let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
                let topRight = detectedRectangle.topRight.scaled(to: imageSize)
                let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
                let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
                let correctedImage = ciImage
                    .cropped(to: boundingBox)
                    .applyingFilter("CIPerspectiveCorrection", parameters: [
                        "inputTopLeft": CIVector(cgPoint: topLeft),
                        "inputTopRight": CIVector(cgPoint: topRight),
                        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                        "inputBottomRight": CIVector(cgPoint: bottomRight)
                        ])
                outputImagesStorage.append(UIImage(ciImage: correctedImage, scale: 1.0, orientation: inputImage.imageOrientation))
            }
        }
        return outputImagesStorage
    }
}
