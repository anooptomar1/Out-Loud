//
//  Utilities.swift
//  Out Loud - Camera To Speech
//
//  Created by Andre Guerra on 12/10/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import CoreGraphics
import ImageIO
import AVFoundation

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}

extension UIImageOrientation {
    func getCGOrientationFromUIImage() -> CGImagePropertyOrientation {
        // call on top of UIImageOrientation to obtain the corresponding CGImage orientation.
        // This is required because UIImage.imageOrientation values don't match to CGImagePropertyOrientation values
        switch self {
        case UIImageOrientation.down: return CGImagePropertyOrientation.down
        case UIImageOrientation.left: return CGImagePropertyOrientation.left
        case UIImageOrientation.right: return CGImagePropertyOrientation.right
        case UIImageOrientation.up: return CGImagePropertyOrientation.up
        case UIImageOrientation.downMirrored: return CGImagePropertyOrientation.downMirrored
        case UIImageOrientation.leftMirrored: return CGImagePropertyOrientation.leftMirrored
        case UIImageOrientation.rightMirrored: return CGImagePropertyOrientation.rightMirrored
        case UIImageOrientation.upMirrored: return CGImagePropertyOrientation.upMirrored
        }
    }
}

extension UIDeviceOrientation {
    func getUIImageOrientationFromDevice() -> UIImageOrientation {
        // return CGImagePropertyOrientation based on Device Orientation
        // This extented function has been determined based on experimentation with how an UIImage gets displayed.
        switch self {
        case UIDeviceOrientation.portrait, .faceUp: return UIImageOrientation.right
        case UIDeviceOrientation.portraitUpsideDown, .faceDown: return UIImageOrientation.left
        case UIDeviceOrientation.landscapeLeft: return UIImageOrientation.up // this is the base orientation
        case UIDeviceOrientation.landscapeRight: return UIImageOrientation.down
        case UIDeviceOrientation.unknown: return UIImageOrientation.up
        }
    }
    func getAVCaptureVideoOrientationFromDevice() -> AVCaptureVideoOrientation? {
        // return AVCaptureVideoOrientation from device
        switch self {
        case UIDeviceOrientation.portrait: return AVCaptureVideoOrientation.portrait
        case UIDeviceOrientation.portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
        case UIDeviceOrientation.landscapeLeft: return AVCaptureVideoOrientation.landscapeLeft
        case UIDeviceOrientation.landscapeRight: return AVCaptureVideoOrientation.landscapeRight
        case UIDeviceOrientation.faceDown: return AVCaptureVideoOrientation.portrait // not so sure about this one
        case UIDeviceOrientation.faceUp: return AVCaptureVideoOrientation.portrait // not so sure about this one
        case UIDeviceOrientation.unknown: return nil
        }
    }
}



