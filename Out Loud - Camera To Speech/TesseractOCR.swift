//
//  TesseractOCR.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 19/10/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import TesseractOCR

class TesseractOCR: NSObject, G8TesseractDelegate {
    let controller: ViewController
    var finishedOCRRequests: Int // number of requests that have already been processed.
    var tesseract: G8Tesseract
    
    init(viewController: ViewController){
        self.controller = viewController
        self.finishedOCRRequests = 0
        self.tesseract = G8Tesseract(language: "eng")
        super.init()
        self.tesseract.delegate = self // grant delegate authority to self
    }
    
    func execute(_ images: [UIImage]){  
        // gets a collection of UIImages for processing
        DispatchQueue.global(qos: .background).async { // OCR routine runs on separate queue as it can take time
            print("Processing \(images.count) images.")
            for image in images{ // iterate thru the list of images
                self.tesseract.image = image // loads image for recognition
                self.tesseract.recognize() // run recognition algorithm

                // routine is not resumed until tesseract is done processing. It's ok since it runs outside the main queue.
                self.finishedOCRRequests += 1 // increments finished requests counter
                print("Done processing. Here's what I got:")

                if let recognizedText = self.tesseract.recognizedText { // OCR found text on the image
                    print(recognizedText)
                    self.controller.goToReading(recognizedText) // feed recognized text to reading routine
                } else { // this piece of detected text rectangle has no text that was recognized
                    print("No text recognized.") // assumes Tesseract returns nil when processing an image with no text.
                    guard let detectedTextAreasCount = self.controller.textDetection.detectedTextAreasCount else {print("Detected text areas is nil. Something went wrong.");return}
                    if self.finishedOCRRequests == detectedTextAreasCount { // Have all detected text rectangles been processed?
                        self.controller.goToCleanup()
                    }
                }
            }
        }
    }
    
    func reset(){ // cancels all OCR requests that may be in progress. This should be called before establishing a liveView feed.
        print("Cancelling pending OCR requests.")
        let cancelOCRRequestsInProgress = self.shouldCancelImageRecognition(for: self.tesseract) // cancel any requests.
        if cancelOCRRequestsInProgress {
            print("OCR requests were probably cancelled. Test.")}
        else {print("Looks like you still have to cancel OCR requests.")}
    }
    
    func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        // called periodically to check if user wants to cancel recognition
        return false
    }
    
}
