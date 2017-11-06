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
    case loading, liveView, capturing, textDetection, processing, reading, noText, cancelling, cleanup
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
                                                  AppState.noText:"No text found.",
                                                  AppState.cancelling:"Cancelled."] // this dictionary contains audio feedback phrases for app state changes.
    var appState = AppState.loading
    var voiceOver: VoiceOver!
    var camera: Camera!
    var capturedCGImage: CGImage! // placeholder for captured image
    var textDetection: TextDetection!
    var ocr: TesseractOCR!
    
    let scaleFactor: CGFloat = UIScreen.main.scale // device dependent scale factor; 3x for the iPhone 7 Plus. Used in the context of CIImages
    
    override func viewDidLoad() {
        print("Executing viewDidLoad")
        super.viewDidLoad()
        self.view.backgroundColor = .black  // chaging the background of my main view to black if there's any real estate left uncovered.
        voiceOver = VoiceOver(viewController: self) // initializes voice over object for this view controller
        camera = Camera(viewController: self) // initializes camera object for this view controller
        ocr = TesseractOCR(viewController: self) // initialize OCR class.
        
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
            case .processing, .reading, .textDetection:
                self.goToCancel()
                break
            default:
                print("Tap functions disabled at this time.")
                break;
            }
        }
    }
    
    
    
    
    
    // APP STATES
    func goToLiveView(){
        DispatchQueue.main.async {
            self.appState = .liveView // update app state
            print("Live view state reached.")
            
            // update user with the state of the app via voice over
            guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
            voiceOver.add(self.stateSpeech[AppState.liveView]!)
            voiceOver.execute()
            
            if let camera = self.camera { // unwrap optional camera variable
                camera.startLiveView()
            } else {fatalError("Unable to unwrap camera object.")}
        }
    }
    func goToCapturing(){
        self.appState = .capturing
        print("Reached capturing state.")
        self.camera.snapPhoto()
        
    }
    func goToTextDetection(){
        self.camera.stopLiveView() // cut video feed
        self.appState = .textDetection
        
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
            self.goToNoText()
        }
    }
    
    func goToApplyOCR(){
        // just display them images now
        print("Applying OCR on text images.")
        guard let ocr = self.ocr else {print("Error on OCR call.");return}
        ocr.execute(self.textDetection.textImages)
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
        self.goToCleanup()
    }
    
    func goToCleanup(){
        // Does the clean up of internal variables to make them ready for any new requests.
        self.appState = .cleanup
        print("Cleanup state reached.")
        if let voiceOver = self.voiceOver {voiceOver.reset()}
        if let ocr = self.ocr {ocr.reset()}
        if let textDetection = self.textDetection {textDetection.reset()}
        
        // Remove previous content from main view before starting live view
        DispatchQueue.main.async { // dispatch to main queue as it is UI related.
            print("Removing previous subviews on top of main view")
            for subview in self.view.subviews{
                subview.removeFromSuperview()
            }
        }
        
        self.goToLiveView()
    }
    
    func goToCancel(){
        self.appState = .cancelling
        print("Cancel request received.")
        guard let voiceOver = self.voiceOver else {fatalError("Unable to unwrap voice over.")}
        voiceOver.add(stateSpeech[AppState.cancelling]!)
        voiceOver.execute()
        self.goToCleanup()
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
    
    
//    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//        // handles transitioning of device orientation.
//    }
}

