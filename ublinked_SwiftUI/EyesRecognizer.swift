//
//  EyesRecognizer.swift
//  ublinked_SwiftUI
//
//  Created by 한태희 on 2022/10/11.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseMLModelDownloader
import MLKitFaceDetection
import MLKit
import AVFoundation
import MLImage
import MLKitVision
import MLKitCommon


class EyesRecognizer: ObservableObject {
    
    func imageOrientation(
      deviceOrientation: UIDeviceOrientation,
      cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
      switch deviceOrientation {
      case .portrait:
        return cameraPosition == .front ? .leftMirrored : .right
      case .landscapeLeft:
        return cameraPosition == .front ? .downMirrored : .up
      case .portraitUpsideDown:
        return cameraPosition == .front ? .rightMirrored : .left
      case .landscapeRight:
        return cameraPosition == .front ? .upMirrored : .down
      case .faceDown, .faceUp, .unknown:
        return .up
      }
    }
    
    func recognize(_ imageData: Data) {
        // High-accuracy landmark detection and face classification
        
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all

        // Real-time contour detection of multiple faces
        // options.contourMode = .all
  
        let visionImage = VisionImage(image: UIImage(data: imageData)!)
//        let visionImage = VisionImage(image: UIImage(named: "Juno")!)
//        visionImage.orientation = UIImage(named: "Juno")!.imageOrientation
        
        
//        guard let cBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//
//        }
        
//        let image = VisionImage(buffer: sampleBuffer)
//        image.orientation = imageOrientation(
//          deviceOrientation: UIDevice.current.orientation,
//          cameraPosition: cameraPosition)
            
        let faceDetector = FaceDetector.faceDetector(options: options)
        
//        let visionImage = VisionImage(image: image)
        
        weak var weakSelf = self
        faceDetector.process(visionImage) { faces, error in
          guard let strongSelf = weakSelf else {
            print("Self is nil!")
            return
          }
          guard error == nil, let faces = faces, !faces.isEmpty else {
            // ...
            return
          }

            print("sadfasdfasdfasdfasdf")
        for face in faces {
          let frame = face.frame
          if face.hasHeadEulerAngleX {
            let rotX = face.headEulerAngleX  // Head is rotated to the uptoward rotX degrees
              
            print(rotX)
          }
          if face.hasHeadEulerAngleY {
            let rotY = face.headEulerAngleY  // Head is rotated to the right rotY degrees
          }
          if face.hasHeadEulerAngleZ {
            let rotZ = face.headEulerAngleZ  // Head is tilted sideways rotZ degrees
          }

          // If landmark detection was enabled (mouth, ears, eyes, cheeks, and
          // nose available):
          if let leftEye = face.landmark(ofType: .leftEye) {
            let leftEyePosition = leftEye.position
          }

          // If contour detection was enabled:
          if let leftEyeContour = face.contour(ofType: .leftEye) {
            let leftEyePoints = leftEyeContour.points
          }
          if let upperLipBottomContour = face.contour(ofType: .upperLipBottom) {
            let upperLipBottomPoints = upperLipBottomContour.points
          }

          // If classification was enabled:
          if face.hasSmilingProbability {
            let smileProb = face.smilingProbability
          }
          if face.hasRightEyeOpenProbability {
            let rightEyeOpenProb = face.rightEyeOpenProbability
          }

          // If face tracking was enabled:
          if face.hasTrackingID {
            let trackingId = face.trackingID
          }
            
            print("\(face.frame)")
            
//            let cropRect = CGRect(x: CGFloat(, y: 0, width: image.size.width, height: image.size.height)
//            let imageRef = image.cgImage!.cropping(to: cropRect);
//            let newImage = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
//
//            guard let image = UIImage(data: imageData) else { return }
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // save
        }
        }

    }
}

