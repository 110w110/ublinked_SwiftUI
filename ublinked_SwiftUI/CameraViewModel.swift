//
//  CameraViewModel.swift
//  ublinked_SwiftUI
//
//  Created by 한태희 on 2022/10/10.
//

import SwiftUI
import AVFoundation
import Combine

class CameraViewModel: ObservableObject {
    
    private let model: Camera
    private let session: AVCaptureSession
    let cameraPreview: AnyView

    private var subscriptions = Set<AnyCancellable>()
    
    @Published var recentImage: UIImage?
    @Published var isFlashOn = false
    @Published var isSilentModeOn = false
    // 추가
    private var numPictures = 1
    
    func getNumPictures() -> String {
        switch numPictures{
        case 1:
            numPictures = 3
            return "Pictures1"
        case 3:
            numPictures = 5
            return "Pictures3"
        case 5:
            numPictures = 10
            return "Pictures5"
        case 10:
            numPictures = 1
            return "Pictures10"
        default:
            numPictures = 1
            return "Pictures1"
        }
    }
    
    var audioPlayer : AVAudioPlayer?
    
    func configure() {
        model.requestAndCheckPermissions()
    }
    
    func switchFlash() {
        isFlashOn.toggle()
    }
    
    func switchSilent() {
        isSilentModeOn.toggle()
    }
    
    func capturePhoto() {
        
        let start = Bundle.main.url(forResource: "start", withExtension: "mp3")
        if let url = start {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                print("start play")
            } catch {
                print(error)
            }
        }
        else {
            print("failed")
        }

        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        model.capturePhoto()
        let ing = Bundle.main.url(forResource: "ing", withExtension: "mp3")
        if let url = ing {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                print("ing play")
            } catch {
                print(error)
            }
        }
        else {
            print("failed")
        }
        let end = Bundle.main.url(forResource: "end", withExtension: "mp3")
        if let url = end {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                print("end play")
            } catch {
                print(error)
            }
        }
        else {
            print("failed")
        }
        print("[CameraViewModel]: Photo captured!")
    }
    
    func changeCamera() {
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
    }
}

class Camera: NSObject, ObservableObject {
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let output = AVCapturePhotoOutput()
    var photoData = Data(count: 0)
    
    @ObservedObject var recognizer = EyesRecognizer()
    @Published var recentImage: UIImage?
    
    // ✅ 추가: 카메라 스위칭
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
    
    // 카메라 셋업 과정을 담당하는 함수, positio
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
        // 사진 옵션 세팅
        let photoSettings = AVCapturePhotoSettings()
        
        self.output.capturePhoto(with: photoSettings, delegate: self)
        print("[Camera]: Photo's taken")
    }
    
    func savePhoto(_ imageData: Data) {
        guard let image = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // 사진 저장하기
        print("[Camera]: Photo's saved")
    }

}
extension Camera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        AudioServicesDisposeSystemSoundID(1108)
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        self.recentImage = UIImage(data: imageData)
        
        recognizer.recognize(imageData)
        
//        self.savePhoto(imageData)
        
        print("[CameraModel]: Capture routine's done")
    }
}
