//
//  CameraViewModel.swift
//  ublinked_SwiftUI
//
//  Created by 한태희 on 2022/10/10.
//

import SwiftUI
import AVFoundation
import Combine

//var pictures = 0

class CameraViewModel: ObservableObject {
    
    let model: Camera
    private let session: AVCaptureSession
    private var isCameraBusy = false
    private var subscriptions = Set<AnyCancellable>()
    let cameraPreview: AnyView
    let hapticImpact = UIImpactFeedbackGenerator()
    var audioPlayer : AVAudioPlayer?
    
    @Published var recentImage: UIImage?
    @Published var isFlashOn = false
    @Published var isSilentModeOn = false
//    @Published var numPictures = 5
    @Published var picCount = 0
    @Published var progressViewOpacity = 0.0
    @Published var shutterEffect = false
    
    
    public func incPicCount(){
        picCount = (picCount + 1) % model.numPictures
        if picCount != 0 {
            progressViewOpacity = 1.0
        } else {
            progressViewOpacity = 0.0
        }
    }
    func picCountSync(){
        picCount = model.picCount
    }
    func configure() {
        model.requestAndCheckPermissions()
    }
    func switchSilent() {
        isSilentModeOn.toggle()
        model.flashMode = isFlashOn == true ? .on : .off
    }
    func changeNumPictures() {
        picCount = 0
        progressViewOpacity = 0.0
        switch model.numPictures{
        case 1:
            model.numPictures = 3
        case 3:
            model.numPictures = 5
        case 5:
            model.numPictures = 10
        case 10:
            model.numPictures = 1
        default:
            model.numPictures = 1
        }
    }
    func capturePhoto() {
        if isCameraBusy == false {
                    
//            while picCount < numPictures {
//                model.capturePhoto()
//            }
            model.capturePhoto()

            hapticImpact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.05)) {
                shutterEffect = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    self.shutterEffect = false
                }
            }
            
//            model.capturePhoto()
            print("count : \(model.imgArr2.count)")

            
        } else {
            print("[CameraViewModel]: Camera's busy.")
        }
        
    }
    func changeCamera() {
        model.changeCamera()
        print("[CameraViewModel]: Camera changed!")
    }
    
    
    init() {
        model = Camera()
        session = model.session
        cameraPreview = AnyView(CameraPreviewView(session: session))
        
        
        model.$recentImage.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.recentImage = pic
        }
        .store(in: &self.subscriptions)
        
        model.$isCameraBusy.sink { [weak self] (result) in
            self?.isCameraBusy = result
        }
        .store(in: &self.subscriptions)
        
        model.$picCount.sink { [weak self] (result) in
            self?.picCount = result
        }
        .store(in: &self.subscriptions)
    }
}

class Camera: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let output = AVCapturePhotoOutput()
    var photoData = Data(count: 0)
    var isSilentModeOn = true
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    @Published var picCount = 0
    @Published var isCameraBusy = false
    @Published var recentImage: UIImage?
    @Published var numPictures = 5
    
    @Published var imgArr2 : [UIImage] = []
    
    func setUpCamera() {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video, position: .back) {
            do { // 카메라가 사용 가능하면 세션에 input과 output을 연결
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    output.isHighResolutionCaptureEnabled = true
                    output.maxPhotoQualityPrioritization = .quality
                }
                session.startRunning() // 세션 시작
            } catch {
                print(error) // 에러 프린트
            }
        }
    }
    func changeCamera() {
        let currentPosition = self.videoDeviceInput.device.position
        let preferredPosition: AVCaptureDevice.Position
        
        switch currentPosition {
        case .unspecified, .front:
            print("후면카메라로 전환합니다.")
            preferredPosition = .back
            
        case .back:
            print("전면카메라로 전환합니다.")
            preferredPosition = .front
            
        @unknown default:
            print("알 수 없는 포지션. 후면카메라로 전환합니다.")
            preferredPosition = .back
        }
        
        if let videoDevice = AVCaptureDevice
            .default(.builtInWideAngleCamera,
                     for: .video, position: preferredPosition) {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                self.session.beginConfiguration()
                
                if let inputs = session.inputs as? [AVCaptureDeviceInput] {
                    for input in inputs {
                        session.removeInput(input)
                    }
                }
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    self.session.addInput(self.videoDeviceInput)
                }
            
                if let connection =
                    self.output.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                
                output.isHighResolutionCaptureEnabled = true
                output.maxPhotoQualityPrioritization = .quality
                
                self.session.commitConfiguration()
            } catch {
                print("Error occurred: \(error)")
            }
        }
    }
    func BlinkingRecognize(image: UIImage) -> (Bool, Bool) {
        if let faceImage = CIImage(image: image) {
            let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
            let faces = faceDetector?.features(in: faceImage, options: [CIDetectorSmile:true, CIDetectorEyeBlink: true])

             if !faces!.isEmpty {
                 for face in faces as! [CIFaceFeature] {
                     let leftEyeClosed = face.leftEyeClosed
                     let rightEyeClosed = face.rightEyeClosed
                     let blinking = face.rightEyeClosed && face.leftEyeClosed
                     let isSmiling = face.hasSmile
                     
                     return (true, rightEyeClosed || leftEyeClosed)
                 }
             } else {
                 print("No faces found")
                 return (false, false)
             }
        }
        return (false, false)
    }
    func requestAndCheckPermissions() {
        // 카메라 권한 상태 확인
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // 권한 요청
            AVCaptureDevice.requestAccess(for: .video) { [weak self] authStatus in
                if authStatus {
                    DispatchQueue.main.async {
                        self?.setUpCamera()
                    }
                }
            }
        case .restricted:
            break
        case .authorized:
            // 이미 권한 받은 경우 셋업
            setUpCamera()
        default:
            // 거절했을 경우
            print("Permession declined")
        }
    }
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = self.flashMode
        self.output.capturePhoto(with: photoSettings, delegate: self)
        print("[Camera]: Photo's taken \(imgArr2.count)")
        self.picCount += 1

    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
//        AudioServicesDisposeSystemSoundID(1108)
        self.isCameraBusy = true
    }
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if isSilentModeOn {
            print("[Camera]: Silent sound activated")
            AudioServicesDisposeSystemSoundID(1108)
        }
        
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if isSilentModeOn {
            AudioServicesDisposeSystemSoundID(1108)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        AudioServicesDisposeSystemSoundID(1108)
        guard let imageData = photo.fileDataRepresentation() else { return }

        self.recentImage = UIImage(data: imageData)
        
//        self.detectFace(imageData)
        self.detectFace(completion: {
            count in
            print("asdfasdfasdfasfsfdfdasfd \(count)")
            self.picCount = count
            if count < self.numPictures {
                self.capturePhoto()
                print("wow")
            }
        }, imageData)
        
        self.isCameraBusy = false
        print("busy false")
    }
    
    
    func detectFace(completion: @escaping (Int) -> (), _ imageData: Data) {
        
        let faceDetector = FaceDetector()
        guard let image = UIImage(data: imageData) else { return }

        let face = UIImageView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        face.image = UIImage(data: imageData)
        let result = faceDetector.getFaceRect(from: face.image!, imageView: face)
        
        var save : Bool = true
        for i in 0..<result.count {
            let rect = result[i]
            
            let imageRef = face.image?.cgImage!.cropping(to: rect)
            let cropImage = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
            
            //UIImage 넘겨야 하는 부분
            let (noerr, blinking) = BlinkingRecognize(image: cropImage)
            if noerr == true && blinking == true {
                save = false
                break
            }
            
        }
        
        if save == true {
            print("OKAY")
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            imgArr2.append(UIImage(named: "Juno")!)
            print("--count : \(imgArr2.count)")
//            self.picCount += 1
            completion(imgArr2.count)
        } else {
            
//            self.picCount -= 1
            completion(0)
        }
        
    }

}


class FaceDetector {
    
    let context = CIContext()
    let opt = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    var detector: CIDetector!
    
    init() {
        detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: opt)
    }
    
    func getFaceRect(from image: UIImage, imageView: UIImageView) -> [CGRect] {
        guard let ciimage = CIImage(image: image) else { return [CGRect.zero] }
        
        let ciImageSize = ciimage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        var features = detector.features(in: ciimage)
        
        var result : [CGRect] = []
        for i in 0..<features.count{

            var faceViewBounds = features[i].bounds.applying(transform)

            let viewSize = imageView.bounds.size
            
            let scale = min(viewSize.width / ciImageSize.height,
                            viewSize.height / ciImageSize.width)
            let offsetY = (viewSize.width - ciImageSize.height * scale) / 2
            let offsetX = (viewSize.height - ciImageSize.width * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY

            var largeCrop = CGRect(x: faceViewBounds.origin.x - faceViewBounds.height / 3, y: faceViewBounds.origin.y - faceViewBounds.width / 10, width: faceViewBounds.width * 1.4, height: faceViewBounds.height * 1.4)
            result.append(largeCrop)
        }
        
        return result
    }
}
