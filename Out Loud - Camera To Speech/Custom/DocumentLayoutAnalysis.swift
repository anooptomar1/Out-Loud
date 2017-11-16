//
//  DocumentLayoutAnalysis.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 15/11/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit

class DocumentLayoutAnalysis: NSObject {
    let controller: ViewController
    var textElements = [String]() // a collection of text data to be analysed.
    
    init(viewController: ViewController){
        self.controller = viewController
        super.init()
    }
    
    func add(_ string: String){
        self.textElements.append(string) // adds a new string element to be analyzed.
    }
    
    func execute(){
        self.controller.appState = .reading // updates app state
        if textElements.count > 0 {
            var sayItAll = String()
            for text in textElements{
                sayItAll += text.trimmingCharacters(in: .newlines)
            }
            self.controller.voiceOver.add(sayItAll)
            self.controller.voiceOver.execute()
        }
        else {
            print("Nothing to say from OCR")
        }
        
    }
    
    func reset(){
        self.textElements = [String]()
    }
    
}
