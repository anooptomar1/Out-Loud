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
    var textElements: [String]? // a collection of text data to be analysed.
    
    init(viewController: ViewController){
        self.controller = viewController
        super.init()
    }
}
