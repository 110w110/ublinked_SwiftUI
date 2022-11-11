//
//  CameraView.swift
//  ublinked_SwiftUI
//
//  Created by 한태희 on 2022/10/10.
//

import SwiftUI
import AVFoundation
// 카메라 전환, 장수 선택, 로딩창, 완료 메시지
struct CameraView: View {
    @ObservedObject var viewModel = CameraViewModel()
//    @ObservedObject var recognizer = EyesRecognizer()

        var body: some View {
            ZStack {
                viewModel.cameraPreview.ignoresSafeArea()
                    .onAppear {
                        viewModel.configure()
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    HStack(spacing: 0) {
                        // 셔터사운드 온오프
                        Button(action: {viewModel.switchFlash()}) {
                            Image(viewModel.getNumPictures())
                                .resizable()
                                .frame(width: 30, height: 30)
                            
                            
//                            Image(systemName: viewModel.isFlashOn ?
//                                  "Pictures1" : "Pictures3")
//                                .foregroundColor(viewModel.isFlashOn ? .yellow : .white)
//                                .frame(width: 15, height: 15)
                        }
                        .padding(.horizontal, 10)
                        
                        Spacer()
                        
                        // 플래시 온오프
                        Button(action: {viewModel.switchSilent()}) {
                            Image(systemName: viewModel.isSilentModeOn ?
                                  "bolt.fill" : "bolt")
                                .foregroundColor(viewModel.isSilentModeOn ? .yellow : .white)
                                .frame(width: 15, height: 15)
                        }
                        .padding(.horizontal, 25)
                        
                        Spacer()
                        
                        Button(action: {viewModel.changeCamera()}) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .frame(width: 15, height: 15)
                            
                        }
                        .padding(.horizontal, 25)
                    }
                    .font(.system(size:25))
                    .padding()
                    
                    Spacer()
                    
                    ZStack(alignment: .bottom){
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.5)
                            .frame(height: 140)
//
                        HStack(alignment: .center){
                            // 찍은 사진 미리보기, 일단 액션 X
                            Button(action: {}) {
                                if let previewImage = viewModel.recentImage {
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Rectangle())
                                        .aspectRatio(1, contentMode: .fit)
                                        .padding(15)
                                } else {
                                    Rectangle()
                                        .stroke(lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                        .padding(15)
                                }
                            }
                            
                            Spacer()
                            
                            // 사진찍기 버튼
                            ZStack{
                                Circle()
                                    .stroke(lineWidth: 5)
                                    .frame(width: 65, height: 65)
                                    .padding()
                                
                                Button(action: {
                                    viewModel.capturePhoto()
//                                    recognizer.recognize()
                                    
                                }) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 55, height: 55)
                                        .padding(15)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Rectangle()
                                    .stroke(lineWidth: 2)
                                    .frame(width: 50, height: 50)
                                    .padding(15)
                                    .opacity(0)
                            }
                        }
                        .padding(30)
                    }
                }
                .foregroundColor(.white)
                .edgesIgnoringSafeArea(.all)
            }
        }
}

struct CameraPreviewView: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
             AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
   
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        
        view.videoPreviewLayer.session = session
        view.backgroundColor = .black
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.connection?.videoOrientation = .portrait

        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
