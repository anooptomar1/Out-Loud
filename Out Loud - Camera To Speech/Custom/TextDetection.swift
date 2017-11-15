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

class TextDetection: NSObject {
    let controller: ViewController
    var inputImage: UIImage // an image to be processed for text areas
    var cropAreas = [CGRect]() // a collection of CGRectangles with the areas of the image that need to be cropped.
    var textImages = [UIImage]()// a collection of UIImages containing text
    var detectedTextAreasCount: Int? // the number of Text areas detected in the image.
    
    init(viewController: ViewController, inputImage: UIImage){
        self.controller = viewController
        self.inputImage = inputImage
        print("Text detection initialized. Input image image orientation: \(inputImage.imageOrientation.rawValue)")
        super.init()
    }
    
    func reset(){
        // cleanup routine
        self.cropAreas = []
        self.textImages = []
        self.detectedTextAreasCount = 0
    }
    
    func detectTextAreas() {
        // runs text detection algorithms and returns a collection of UIImage's to apply OCR. Return nil if no text has been found.
        guard let cgImage = self.inputImage.cgImage else {print("Unable to convert image to CGImage"); return}// generate CGImage from the UIImage
        let inputImageOrientation = self.inputImage.imageOrientation.getCGOrientationFromUIImage()
        
        // Configure text detection as a Vision request
        let textDetectionRequest = VNDetectTextRectanglesRequest(completionHandler: {(req, error) in
            
            if let error = error {
                print("Detection failed. Error: \(error)")
                return
            }
            if let results = req.results {self.detectedTextAreasCount = results.count} // update internal variable with the number of detected areas (relevant info for other pieces of the app)
            
            req.results?.forEach({(res) in
                guard let observation = res as? VNTextObservation else {print("No observation detected.");return}
                let boundingBox = observation.boundingBox
                print("Bounding box: ", boundingBox)
                self.cropAreas.append(boundingBox)
                
                DispatchQueue.main.async { // dispatching to main queue since there is an UI update
                    // Use the bounding box to determine where in the view frame to draw a rectangle corresponding to the detection.
                    let conversionRatio = self.controller.view.frame.width / self.inputImage.size.width
                    let scaledHeight = conversionRatio * self.inputImage.size.height
                    let x = self.controller.view.frame.width * boundingBox.origin.x // + imageView.frame.origin.x
                    let width = self.controller.view.frame.width * boundingBox.width
                    let height = scaledHeight * boundingBox.height
                    let y = scaledHeight * (1-boundingBox.origin.y) - height // + imageView.frame.origin.y
                    let textRectangle = CGRect(x: x, y: y, width: width, height: height) // rectangle that needs to be used in order to crop the image before feeding it to OCR
                    
                    
                    // Draw rectangles on UI for areas of detected text
                    let redBox = UIView()
                    redBox.backgroundColor = .red
                    redBox.alpha = 0.3
                    redBox.frame = textRectangle
                    self.controller.view.addSubview(redBox)
                    
                }
            })
            guard let detectedAreas = self.detectedTextAreasCount else {print("Detected areas count is nil."); self.controller.goToNoText(); return}
            if detectedAreas > 0 {
                self.applyFilters() // once done detecting all rectangles, filter images
            } else {
                self.controller.goToNoText()
            }
            
        })
        

        let textDetectionHandler = VNImageRequestHandler(cgImage: cgImage, orientation: inputImageOrientation, options: [:])
        
        DispatchQueue.global(qos: .background).async {
            do {
                try textDetectionHandler.perform([textDetectionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    private func applyFilters(){
        print("\(cropAreas.count) text areas detected.")
        
        
        
        // consider calling the rectangles sorting routine here.
        //let sortedCropAreas = sortDetectedAreas(cropAreas)
        let sortedCropAreas = cropAreas
        
        let context = CIContext(options: nil) // context of the CIImage; CIImages cannot be drawn in the UI without this o.O
        guard let ciImage = CIImage(image: self.inputImage) else {print("Unable to convert to CIImage."); return} // convert to CIImage in order to enable easy image filters
        // maybe I need to properly rotate the generated CIImage to the corresponding UIImage's orientation
        // doing this the hardcoded way for the device in portrait mode. Add an extension to CIImage in order to rotate according to corresponding UIImageOrientation.
        
        // apply rotation
        let rotationTransform = CGAffineTransform.init(rotationAngle: CGFloat(3*Double.pi/2)) //rotation by 90 degrees
        guard let rotationFilter = CIFilter(name: "CIAffineTransform") else {print("unable to create filter");return}
        rotationFilter.setValue(ciImage, forKey: "inputImage")
        rotationFilter.setValue(rotationTransform, forKey: "inputTransform")
        guard let ciImageRotated = rotationFilter.outputImage else {print("Unable to apply rotation.");return}
        
        // apply translation
        let translationTransform = CGAffineTransform.init(translationX: 0, y: ciImageRotated.extent.height)
        guard let translationFilter = CIFilter(name: "CIAffineTransform") else {print("Unable to create translation filter."); return}
        translationFilter.setValue(ciImageRotated, forKey: "inputImage")
        translationFilter.setValue(translationTransform, forKey: "inputTransform")
        guard let ciImageFixed = translationFilter.outputImage else {print("Unable to translate image."); return}
        print("Processing input: ", self.inputImage)
        print("Processing CIImage: \(ciImageFixed.extent.width) width x \(ciImageFixed.extent.height) heigth.")
        
        // apply color controls
//        guard let colorCorrectionFilter = CIFilter(name: "CIColorControls",
//                                                   withInputParameters: ["inputImage":ciImageFixed,
//                                                                         "inputSaturation":0,
//                                                                         "inputContrast":32]) else {print("Unable to create color correction filter."); return}
//        guard let ciImageColorCorrection = colorCorrectionFilter.outputImage else {print("Unable to apply color correciton");return}
        
        // Apply crop
        for rectangle in sortedCropAreas{
            print("Normalized rectangle: \(rectangle)")
            let cropRectangle = CGRect(x: rectangle.origin.x * ciImageFixed.extent.width,
                                       y: rectangle.origin.y * ciImageFixed.extent.height,
                                       width: rectangle.width * ciImageFixed.extent.width,
                                       height: rectangle.height * ciImageFixed.extent.height)
            print("Crop rectangle: \(cropRectangle)")
            guard let cropFilter = CIFilter(name: "CICrop", withInputParameters: ["inputImage":ciImageFixed,
                                                                                  "inputRectangle":cropRectangle])
                else {print("Unable to create filter."); continue}// creates a crop filter to apply on text region
//            cropFilter.setValue(ciImageFixed, forKey: "inputImage") // loads image content to filter
//            cropFilter.setValue(cropRectangle, forKey: "inputRectangle") // defines crop area
            guard let croppedImage = cropFilter.outputImage else {print("Unable to create image from filter."); continue}
            guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else {print("Unable to create CGImage from filter."); continue}
            let uiImage = UIImage(cgImage: cgImage)
            print("Generated UIImageOrientation: \(uiImage.imageOrientation.rawValue)")
            self.textImages.append(uiImage)
        }
        print("Done filtering.")
        self.controller.goToApplyOCR()
    }
    
    private func sortDetectedAreas(_ rectanglesToSort: [CGRect]) -> [CGRect]{
        // sorts reading areas according to their position so that they are read in a manner that makes sense.
        // input: an array of unsorted CGRect;
        // output: the same array sorted from top to bottom, left to right.
        var unsortedRectangles = rectanglesToSort // creates a copy of the rectangle to be sorted. I need this line because rectanglesToSort is an immutable 'let' constant.
        
        var sortedRectangles: [CGRect] = [unsortedRectangles.removeFirst()] // initializes sorted array containing the first element of the unsorted rectangles.
        let verticalTolerance: CGFloat = 0.05 // Vertical pixel tolerance to consider items within the same vertical line coordinate. This value can assume any values from 0.0 to 1.0 and relates to percentage.
        
        for rectangleToCheck in unsortedRectangles{ // loads unsorted rectangle to check. Remember the first element is already present in the sorted version of the array
            let sortedCount = sortedRectangles.count // updates the element count in the sorted array
            for rectangleAlreadySorted in sortedRectangles { // load the elemnts in the already sorted rectangles list to be checked against
                let yRectangleToCheck = rectangleToCheck.origin.y // remember this y value is normalized to the image's dimensions varying from 0.0 to 1.0
                let yRectangleAlreadySorted = rectangleAlreadySorted.origin.y // same statement as the above is valid.
                let verticalDifference = abs(yRectangleToCheck - yRectangleAlreadySorted) // normalized difference between the 2 rectangles. [0.0,1.0]
                if verticalDifference <= verticalTolerance { // consider these 2 rectangles to be in the same vertical postition
                    // compare x coordinates
                    let xRectangleToCheck = rectangleToCheck.origin.x
                    let xRectangleAlreadySorted = rectangleAlreadySorted.origin.x
                    // assuming 2 rectangles cannot be detected within the same vertical postion and have the same x coordinate (even with a tolerance).
                    if xRectangleToCheck > xRectangleAlreadySorted { // new rectangle is located to the right of the existing in the sorted array.
                        guard let sortedRectangleIndex = sortedRectangles.index(of: rectangleAlreadySorted) else {fatalError("Could not retrieve index of sorted rectangle.")} // returns the index of the sorted rectangle in the current analysis
                        sortedRectangles.insert(rectangleToCheck, at: sortedRectangleIndex) // places the rectangle in this check in the place of the already sorted rectangle.
                        break // break the sorted rectangles loop since the sorted array will only have bigger elements on next iterations.
                    }
                }
                else { // rectangles have different vertical positions
                    if yRectangleToCheck > yRectangleAlreadySorted { // new rectangle is above the existing one in the sorted array, so it must be added at the index of the sorted one.
                        guard let sortedRectangleIndex = sortedRectangles.index(of: rectangleAlreadySorted) else {fatalError("Could not retrieve index of sorted rectangle.")} // returns the index of the sorted rectangle in the current analysis
                        sortedRectangles.insert(rectangleToCheck, at: sortedRectangleIndex) // places the rectangle in this check in the place of the already sorted rectangle.
                        break
                    }
                } // if the other option, rectangle below, do nothing until we have reached the end of the sorted array;
            }
            if sortedCount == sortedRectangles.count { // we have reached the end of the sorted array and found nothing bigger
                sortedRectangles.append(rectangleToCheck)
            }
        }
        return sortedRectangles
    }
}
