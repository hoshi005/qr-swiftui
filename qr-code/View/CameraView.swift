//
//  CameraView.swift
//  qr-code
//
//  Created by Susumu Hoshikawa on 2023/04/09.
//

import SwiftUI
import AVKit

/// CameraView Using AVCaptureVideoPreviewLayer
struct CameraView: UIViewRepresentable {
    
    var frameSize: CGSize
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIViewType(frame: .init(origin: .zero, size: frameSize))
        view.backgroundColor = .clear
        
        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.frame = .init(origin: .zero, size: frameSize)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.masksToBounds = true
        view.layer.addSublayer(cameraLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
    typealias UIViewType = UIView
    
}
