//
//  ViewController.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 11/10/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import AVFoundation
import TesseractOCR

enum AppState{
    case loading, liveView, capturing, textDetection, imageFiltering, applyOCR, processing, reading, noText, chilling
    /*
     loading: app is loading for the first time
     liveView: app is presenting the live view from the camera and awaiting a tap to capture image
     capturing: app is capturing image
     textDetection: Vision framework is processing image for text
     imageFiltering: text has been detected and captured image will now be filtered to be sent to OCR.
     applyOCR: images have been filtered and are ready for OCR.
     processing: app has completed capturing and will now run OCR on image for reading
     reading: app is outputing speech of recognized text
     noText: no text found on the image. Go back to liveView
     chilling: a test state just to keep the last image capture on display. Exit this state is thru a tap to go to LiveView again.
     */
}



class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private var stateSpeech: [AppState:String] = [AppState.liveView:"Camera view. Tap to begin.",
                                                  AppState.processing:"Processing.",
                                                  AppState.noText:"No text found."] // this dictionary contains audio feedback phrases for app state changes.
    var appState = AppState.loading
    var voiceOver: VoiceOver!
    var camera: Camera!
    var capturedCGImage: CGImage! // placeholder for captured image
    var textDetection: TextDetection!
    let scaleFactor: CGFloat = UIScreen.main.scale // device dependent scale factor; 3x for the iPhone 7 Plus. Used in the context of CIImages
    
    override func viewDidLoad() {
        print("Executing viewDidLoad")
        super.viewDidLoad()
        self.view.backgroundColor = .black  // chaging the background of my main view to black if there's any real estate left uncovered.
        voiceOver = VoiceOver(viewController: self) // initializes voice over object for this view controller
        camera = Camera(viewController: self) // initializes camera object for this view controller
        
        // SETUP CODED GESTURES
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap)) // instantiates a gesture recognizer
        tap.delegate = self // delegates authority to ViewController
        self.view.addGestureRecognizer(tap) // adds gesture to main view
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1

        // ADITIONAL ACTIONS
        self.goToLiveView() // start live view just after view is loaded.
    }

    
    
    
    // GESTURES ACTIONS
    @IBAction func handleTap(sender: UITapGestureRecognizer){
        if sender.state == .ended{ // if gesture capture has ended
            switch self.appState { // check current app state and take action accordingly.
            case .liveView:
                self.goToCapturing()
                break;
            case .reading:
                self.goToCancelReading()
            case .applyOCR:
                self.goToLiveView()
            default:
                print("Tap functions disabled at this time.")
                break;
            }
        }
    }
    
    
    
    
    
    // APP STATES
    func goToLiveView(){
        print("Live view state reached.")
        self.appState = .liveView // update app state
        
        // update user with the state of the app via voice over
        guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
        voiceOver.add(stateSpeech[AppState.liveView]!)
        voiceOver.execute()

        // Remove previous content from main view before starting live view
        print("Removing previous subviews on top of main view")
        for subview in self.view.subviews{
            subview.removeFromSuperview()
        }
        
        if let camera = self.camera { // unwrap optional camera variable
            camera.startLiveView()
        } else {fatalError("Unable to unwrap camera object.")}
        
    }
    func goToCapturing(){
        self.appState = .capturing
        print("Reached capturing state.")
        self.camera.snapPhoto()
        
    }
    func goToTextDetection(){
        self.camera.stopLiveView() // cut video feed
        self.appState = .processing
        
        // update user with the state of the app via voice over
        guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
        voiceOver.add(stateSpeech[AppState.processing]!)
        voiceOver.execute()

        if let image = self.camera.lastPhoto { // if the camera image is available
            self.displayImageOnView(image, xPos: 0, yPos: 0) // display image on the UI

            // Apply text detection
            self.textDetection = TextDetection(viewController: self, inputImage: image)
            if let textDetection = self.textDetection {
                textDetection.detectTextAreas()
            }
            // next state is triggered when text detection has finished.
        } else { // no image is available for processing
            self.goToLiveView()
        }
    }
    
    func goToReading(_ string: String){
        self.appState = .reading
        print("Reading state reached.")
        guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
        voiceOver.add(string)
        voiceOver.execute()
    }
    
    func goToNoText(){
        self.appState = .noText
        print("No text state reached.")
        guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
        voiceOver.add(stateSpeech[AppState.noText]!)
        voiceOver.execute()
        self.goToLiveView()
    }
    
    func goToCancelReading(){
        print("Cancel reading request received.")
        guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
        voiceOver.reset()
        self.goToLiveView()
    }
    
    func goToApplyOCR(){
        // just display them images now
        self.appState = .applyOCR
        print("Applying OCR on text images.")
        for image in self.textDetection.textImages{
            let ocr = TesseractOCR(viewController: self)
            ocr.execute(image)
        }
//        DispatchQueue.main.async {
//            for image in self.textDetection.textImages{
//                print(image)
//                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 400, height: 50))
//                imageView.contentMode = .scaleAspectFill
//                imageView.image = image
//                self.view.addSubview(imageView)
//            }
//        }
    }
    
    
    
    
    
    // OTHER FUNCTIONS
    func displayImageOnView(_ image: UIImage, xPos: CGFloat, yPos: CGFloat){
        DispatchQueue.main.async {
            let conversionRatio = self.view.frame.width / image.size.width
            let scaledHeigth = conversionRatio * image.size.height
            let imageView = UIImageView(frame: CGRect(x: xPos, y: yPos, width: self.view.frame.width, height: scaledHeigth))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            print(imageView)
            print("Adding new subview with image.")
            self.view.addSubview(imageView) // this will be removed from the view when we return to live view mode.
        }
    }
    
    
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        // updates user regarding current ocr processing
        // if processing has been completed. discover delegate method that does this. this method may not be called after tesseract is done processing
    }
    
//    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//        // handles transitioning of device orientation.
//    }
}

