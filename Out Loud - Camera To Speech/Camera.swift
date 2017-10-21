//
//  Camera.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 17/10/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//
//  Handles all features related to camera, such as live view display and photo capture.

import UIKit
import AVFoundation

class Camera: NSObject, AVCapturePhotoCaptureDelegate {
    private let captureSession = AVCaptureSession() // initializes capture session
    private var device: AVCaptureDevice! // camera device being used.
    private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video) // authorization status of the camera device
    private var capturePhotoOutput = AVCapturePhotoOutput()
    

    let controller: ViewController // in order to interact with the calling view controller of this class
    var lastPhoto: UIImage!
    
    // Initialization
    init(viewController: ViewController){
        self.controller = viewController
        super.init() // initializer super class
        self.checkCameraAuthorization() // runs a check for current authorizations on camera updates if required.
        self.configureCaptureSession() // configures the capture session. Session preset, all inputs and outputs are added here.
        self.addPreviewToCaptureSession()
    }
    
    private func defaultDevice() -> AVCaptureDevice{
        // returns the default device to be used in the capture session.
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) { //
            return device // use dual rear cameras when available
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device // use default back facing camera
        } else{
            fatalError("No back camera available on this device.")
        }
    }
    
    private func checkCameraAuthorization(){
        // Checking for current authorizations on the device
        if self.cameraAuthorizationStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {
                (granted:Bool) -> Void in
                if granted {
                    // camera access granted
                    print("Camera access granted.")
                    
                }
                else {
                    // camera access denined
                    print("Camera access denied. Impossible to operate app. Please review and authorize.")
                }
                self.cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video) // update camera status
            })
        }
    }
    
    private func configureCaptureSession(){
        // get video input from default camera
        let videoCaptureDevice = self.defaultDevice()
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {print("Unable to obtain video input from default camera."); return}
        
        // create and configure photo output
        let capturePhotoOutput = AVCapturePhotoOutput()
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        capturePhotoOutput.isLivePhotoCaptureEnabled = false
        
        // check that you can add input and output to session
        guard self.captureSession.canAddInput(videoInput) else {print("Unable to add input to capture session."); return}
        guard self.captureSession.canAddOutput(capturePhotoOutput) else {print("Unable to add output to capture session"); return}
        
        // configure session
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = .photo
        self.captureSession.addInput(videoInput)
        self.captureSession.addOutput(capturePhotoOutput)
        self.captureSession.commitConfiguration()
        
        self.capturePhotoOutput = capturePhotoOutput // I will need this later, this is why it is saved in an outer scope.
    }
    
    private func addPreviewToCaptureSession(){
        let previewContainer = self.controller.view.layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect // // Preserve aspect ratio; fit within layer bounds;
        
        previewLayer.frame = previewContainer.bounds
        previewLayer.contentsGravity = kCAGravityResizeAspectFill
        previewContainer.insertSublayer(previewLayer, at: 0)
    }
    
    // Start running live view
    func startLiveView(){
        print("Live capture start call.")
//        print("\(self.classForCoder)/" + #function)
        DispatchQueue.global(qos: .userInteractive).async {
            if self.captureSession.isRunning {
                print("already running")
                return
            }
            self.captureSession.startRunning()
            print("Live capture started.")
        }
        
    }
    
    // Stop running live view
    func stopLiveView(){
        print("Live capture stop call.")
        DispatchQueue.global(qos: .userInteractive).async {
            if !self.captureSession.isRunning {
                print("already stopped")
                return
            }
            self.captureSession.stopRunning()
            print("Live capture stopped.")
        }
    }
    
    
    func snapPhoto(){
        let deviceOrientation = UIDevice.current.orientation // retrieve current orientation from the device
        guard let photoOutputConnection = capturePhotoOutput.connection(with: AVMediaType.video) else {fatalError("Unable to establish input>output connection")}// setup a connection that manages input > output
        guard let videoOrientation = deviceOrientation.getAVCaptureVideoOrientationFromDevice() else {return}
        photoOutputConnection.videoOrientation = videoOrientation // update photo's output connection to match device's orientation
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        self.capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self) // trigger image capture. It appears to work only if the capture session is running.
    }
    
    // Delegate methods of the photo capture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // capture image finished
        print("Image captured.")
//        let orientation = UIDevice.current.orientation.getUIImageOrientationFromDevice() // generates an UIImage orientation from the current device's orientation.
//        guard let imageData = photo.cgImageRepresentation() else {print("Unable to generate CGImage"); self.lastPhoto = nil; self.controller.goToProcessing(); return}
//        let uiImage = UIImage(cgImage: imageData.takeRetainedValue(), scale: 1.0, orientation: orientation)
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.");
            self.lastPhoto = nil; self.controller.goToProcessing();
            return}
        guard let uiImage = UIImage(data: imageData) else {
            print("Unable to generate UIImage from image data.");
            self.lastPhoto = nil; self.controller.goToProcessing();
            return}
        self.lastPhoto = uiImage // if code execution reaches this place, the UIImage has been successfully generated.
        print("UIImage generated. Orientation: \(uiImage.imageOrientation.rawValue)")
        self.controller.goToProcessing()
    }
    
}

class VideoPreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {return videoPreviewLayer.session}
        set {videoPreviewLayer.session = newValue}
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    private var orientationMap: [UIDeviceOrientation: AVCaptureVideoOrientation] = [
        UIDeviceOrientation.portrait : AVCaptureVideoOrientation.portrait,
        UIDeviceOrientation.portraitUpsideDown : AVCaptureVideoOrientation.portraitUpsideDown,
        UIDeviceOrientation.landscapeLeft : AVCaptureVideoOrientation.landscapeLeft,
        UIDeviceOrientation.landscapeRight : AVCaptureVideoOrientation.landscapeRight
    ]
    
    func updateVideoOrientationFromDeviceOrientation(){
        if let videoPreviewLayerConnection = videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = orientationMap[deviceOrientation], deviceOrientation.isPortrait || deviceOrientation.isLandscape else {return}
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    
}
