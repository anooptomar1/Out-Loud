//
//  VoiceOver.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 15/10/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//
//  Does all the stuff required to speak text out loud
//  Idea: instantiate this class, load all the strings you'd like voiced over using the add method and execute.

import UIKit
import AVFoundation

class VoiceOver: NSObject, AVSpeechSynthesizerDelegate {
    let controller: ViewController // a instance copy (by reference) of the ViewController that called it. This allows this class to read/write data back to its calling view controller
    var queue = [String]() // the of texts that are to be voiced out loud;
    let speech = AVSpeechSynthesizer() // initializes a synthesizer. This needs to be in this global scope to enable verification of any speeches in progress
    var voice: AVSpeechSynthesisVoice! // voice selection
    
    
    init(viewController: ViewController){
        self.controller = viewController
        super.init() // superclass initializer
        
        speech.delegate = self // grants delegate authority to self
        // setting up default voice (the first available enhanced quality voice available in your device that matches your region selection in the Settings App OR simply one that satisfies that last condition).
        for availableVoice in AVSpeechSynthesisVoice.speechVoices(){ // iterate thru available voices
            if ((availableVoice.language == AVSpeechSynthesisVoice.currentLanguageCode()) &&
                (availableVoice.quality == AVSpeechSynthesisVoiceQuality.enhanced)){ // If you have found the enhanced version of the currently selected language voice amongst your available voices... Usually there's only one selected.
                self.voice = availableVoice
                print("\(availableVoice.name) selected as voice for uttering speeches. Quality: \(availableVoice.quality.rawValue)")
            }
        }
        if let selectedVoice = self.voice { // if sucessfully unwrapped, the previous routine was able to identify one of the enhanced voices
            print("The following voice identifier has been loaded: ",selectedVoice.identifier)
        } else {
            self.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode()) // load any of the voices that matches the current language selection for the device in case no enhanced voice has been found.
        }
    }
    
    func add(_ string: String){
        // adds a new string to the voice over queue
        self.queue.append(string)
    }
    
    func execute(){
        // utters all strings in the queue
        for text in self.queue{ // iterates thru texts in the processing queue
            let utterance = AVSpeechUtterance(string: text) // loads a new utterance to be spoken
            guard let voice = self.voice else {fatalError("Error loading voice")} // unwrap voice
            utterance.voice = voice // load voice selection
            speech.speak(utterance) // say it out loud
        }
        self.queue = [String]() // reset queue when finished.
    }
    
    func reset(){
        // stop any utterances in progress and empty queue
        if speech.isSpeaking { // if there is a speech in progress
            speech.stopSpeaking(at: AVSpeechBoundary.immediate) // stop speech immediately
        }
        let utterance = AVSpeechUtterance(string: "Reading cancelled.") // loads utterance with corresponding app state voice over
        guard let voice = self.voice else {fatalError("Error loading voice")} // unwrap voice
        utterance.voice = voice // load voice selection
        speech.speak(utterance) // say it out loud
        self.queue = [String]() // reset queue
    }
    
    // delegate method
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if ((self.queue.count == 0) &&
            (self.controller.appState == AppState.reading) &&
            (!self.speech.isSpeaking)) { // if there's nothing more to be said and app was on reading state and there's nothing currently being said
            self.controller.goToLiveView() // go back to live view
        }
    }
}
