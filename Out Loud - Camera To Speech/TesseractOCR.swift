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
    var recognizedText: String! // this will save the recognized text and make it available on this class' instance
    let controller: ViewController
    
    init(viewController: ViewController){
        self.controller = viewController
        super.init()
    }
    
    func execute(_ image: UIImage){
        // gets and UIImage for processing and run OCR
        DispatchQueue.global(qos: .userInteractive).async { // OCR routine runs on separate queue as it can take time
            guard let tesseract = G8Tesseract(language: "eng") else {print("Error on instantiating Tesseract");return}
            tesseract.delegate = self // grant delegate authority to ViewController
            tesseract.image = image // loads image for recognition
            tesseract.recognize() // run recognition algorithm
            // routine is not resumed until tesseract is done processing. It's ok since it runs outside the main queue.
            print("Done processing. Here's what I got:")
            if let recognizedText = tesseract.recognizedText {
                print(recognizedText)
                self.recognizedText = recognizedText
                self.controller.goToReading(self.recognizedText)
            } else {
                print("error on text recognition")
                self.recognizedText = nil
                self.controller.goToNoText()
            }
        }
    }
    
    func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        // called periodically to check if user want to cancel recognition
        return false
    }
}
