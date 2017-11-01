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
    
    init(viewController: ViewController, inputImage: UIImage){
        self.controller = viewController
        self.inputImage = inputImage
        print("Text detection initialized. Input image image orientation: \(inputImage.imageOrientation.rawValue)")
        super.init()
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
                    
//                    let croppedImage = ciImage.cropped(to: boundingBox) // crop original image according to detected bounding box.
//                    let croppedUIImage = UIImage(ciImage: croppedImage) // convert to UIImage
//                    self.textImages.append(croppedUIImage) // add to output storage
//                    let imageView = UIImageView(image: croppedUIImage)
//                    let conversionRatioCropped = self.controller.view.frame.width / croppedUIImage.size.width
//                    let scaledHeightCropped = conversionRatioCropped * croppedUIImage.size.height
//                    imageView.frame = CGRect(x: 0, y: 0, width: self.controller.view.frame.width, height: scaledHeightCropped)
//                    self.controller.view.addSubview(imageView)
                }
            })
            self.applyFilters() // once done detecting all rectangles, filter images
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
        let context = CIContext(options: nil) // context of the CIImage; CIImages cannot be drawn in the UI without this o.O
        guard let ciImage = CIImage(image: self.inputImage) else {print("Unable to convert to CIImage."); return} // convert to CIImage in order to enable easy image filters
        // maybe I need to properly rotate the generated CIImage to the corresponding UIImage's orientation
        // doing this the hardcoded way for the device in portrait mode. Add an extension to CIImage in order to rotate according to corresponding UIImageOrientation.
        let rotationTransform = CGAffineTransform.init(rotationAngle: CGFloat(3*Double.pi/2)) //rotation by 90 degrees
        guard let rotationFilter = CIFilter(name: "CIAffineTransform") else {print("unable to create filter");return}
        rotationFilter.setValue(ciImage, forKey: "inputImage")
        rotationFilter.setValue(rotationTransform, forKey: "inputTransform")
        guard let ciImageRotated = rotationFilter.outputImage else {print("Unable to apply rotation.");return}
        let translationTransform = CGAffineTransform.init(translationX: 0, y: ciImageRotated.extent.height)
        guard let translationFilter = CIFilter(name: "CIAffineTransform") else {print("Unable to create translation filter."); return}
        translationFilter.setValue(ciImageRotated, forKey: "inputImage")
        translationFilter.setValue(translationTransform, forKey: "inputTransform")
        guard let ciImageFixed = translationFilter.outputImage else {print("Unable to translate image."); return}
        print("Processing input: ", self.inputImage)
        print("Processing CIImage: \(ciImageFixed.extent.width) width x \(ciImageFixed.extent.height) heigth.")
        for rectangle in self.cropAreas{
            print("Normalized rectangle: \(rectangle)")
            let cropRectangle = CGRect(x: rectangle.origin.x * ciImageFixed.extent.width,
                                       y: rectangle.origin.y * ciImageFixed.extent.height,
                                       width: rectangle.width * ciImageFixed.extent.width,
                                       height: rectangle.height * ciImageFixed.extent.height)
            print("Crop rectangle: \(cropRectangle)")
            guard let cropFilter = CIFilter(name: "CICrop") else {print("Unable to create filter."); continue}// creates a crop filter to apply on text region
            cropFilter.setValue(ciImageFixed, forKey: "inputImage") // loads image content to filter
            cropFilter.setValue(cropRectangle, forKey: "inputRectangle") // defines crop area
            guard let croppedImage = cropFilter.outputImage else {print("Unable to create image from filter."); continue}
            guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else {print("Unable to create CGImage from filter."); continue}
            let uiImage = UIImage(cgImage: cgImage)
            print("Generated UIImageOrientation: \(uiImage.imageOrientation.rawValue)")
            self.textImages.append(uiImage)
        }
        print("Done filtering.")
        self.controller.goToApplyOCR()
        
    }
}
