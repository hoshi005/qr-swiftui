//
//  ScannerView.swift
//  qr-code
//
//  Created by Susumu Hoshikawa on 2023/04/09.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    @State private var cameraPermission: Permission = .idle
    
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    @Environment(\.openURL) private var openURL
    
    @StateObject private var qrDelegate = QRScannerDelegate()
    
    @State private var scannedCode = ""
    
    var body: some View {
        VStack(spacing: 8.0) {
            Button {
                
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Color("AccentColor"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Place the QR code inside the area")
                .font(.title3)
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 20.0)
            
            Text("Scanning will start automatically")
                .font(.callout)
                .foregroundColor(Color.gray)
            
            Spacer(minLength: 0)
            
            /// Scanner
            GeometryReader {
                let size = $0.size
                
                ZStack {
                    
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.97)
                    
                    ForEach(0...4, id: \.self) { index in
                        let rotation = Double(index) * 90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                            .trim(from: 0.61, to: 0.64)
                            .stroke(
                                Color.accentColor,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                            )
                            .rotationEffect(.init(degrees: rotation))
                    }
                }
                // square shape.
                .frame(width: size.width, height: size.width)
                // Scanner Animation
                .overlay(alignment:.top, content: {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 : -15)
                        .offset(y: isScanning ? size.width : 0)
                })
                // to make it center.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 15)
            
            Button {
                if !session.isRunning && cameraPermission == .approved {
                    reactivateCamera()
                    activateScannerAnimation()
                }
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            
            Spacer(minLength: 45)

        }
        .padding(15)
        // checking camera permission, when the view is visible
        .onAppear(perform: checkCameraPermission)
        .alert(errorMessage, isPresented: $showError) {
            if cameraPermission == .denied {
                Button("Settings") {
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingsURL = URL(string: settingsString) {
                        // open App's setting, Using openURL SwiftUI API
                        openURL(settingsURL)
                    }
                }
                
                // along with cancel button
                Button("Cancel", role: .cancel) {
                    
                }
            }
        }
        .onChange(of: qrDelegate.scannedCode) { newValue in
            if let code = newValue {
                scannedCode = code
                
                // when the first code scan is available, immediately stop the camera,
                session.stopRunning()
                
                // stop scanner animation
                deActivateScannerAnimation()
                
                // clearing the data on delegate
                qrDelegate.scannedCode = nil
            }
        }
    }
    
    func reactivateCamera() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    func activateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)) {
            isScanning = true
        }
    }
    
    func deActivateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.85)) {
            isScanning = false
        }
    }
    
    /// checking camera permission
    func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty {
                    setupCamera()
                } else {
                    session.startRunning()
                }
            case .notDetermined:
                // requesting camera access
                if await AVCaptureDevice.requestAccess(for: .video) {
                    cameraPermission = .approved
                    setupCamera()
                } else {
                    cameraPermission = .denied
                    presentError("カメラが使えないとダメです")
                }
            case .denied, .restricted:
                cameraPermission = .denied
                presentError("カメラが使えないとダメです")
            default: break
            }
        }
    }
    
    func setupCamera() {
        do {
            // finding back camera
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back).devices.first else {
                presentError("UNKNOWN DEVICE ERROR")
                return
            }
            
            // camera input
            let input = try AVCaptureDeviceInput(device: device)
            
            // for extra safety
            // checking wheter input & output can be added to the session
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("UNKNOWN INPUT/OUTPUT ERROR")
                return
            }
            
            // adding input & output to camera session
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            // setting output config to read QRCode
            qrOutput.metadataObjectTypes = [.qr]
            
            // adding delegate to retreive the fetched QRCode from camera
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            // MEMO: session must be started on background thread
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            activateScannerAnimation()
        } catch {
            presentError(error.localizedDescription)
        }
    }
    
    func presentError(_ message: String) {
        errorMessage = message
        showError.toggle()
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
