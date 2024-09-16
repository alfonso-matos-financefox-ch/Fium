//
//  InviteView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import AVFoundation

struct InviteView: View {
    @State private var isShowingScanner = false
    @State private var scannedCode: String?

    var body: some View {
        VStack(spacing: 20) {
            if let code = scannedCode {
                Text("Código Escaneado:")
                    .font(.headline)
                Text(code)
                    .font(.largeTitle)
            } else {
                Text("Escanea el código QR de invitación")
                    .font(.headline)
            }

            Button(action: {
                isShowingScanner = true
            }) {
                Text("Escanear QR")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $isShowingScanner) {
                QRCodeScannerView { result in
                    switch result {
                    case .success(let code):
                        scannedCode = code
                        isShowingScanner = false
                    case .failure(let error):
                        print("Scanning failed: \(error.localizedDescription)")
                        isShowingScanner = false
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Invitar Amigos")
    }
}

// QR Code Scanner View
struct QRCodeScannerView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let code = metadataObject.stringValue {
                parent.completion(.success(code))
            } else {
                parent.completion(.failure(NSError(domain: "No QR code detected", code: -1, userInfo: nil)))
            }
        }
    }

    typealias UIViewControllerType = AVCaptureViewController
    var completion: (Result<String, Error>) -> Void

    func makeUIViewController(context: Context) -> AVCaptureViewController {
        let controller = AVCaptureViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: AVCaptureViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

class AVCaptureViewController: UIViewController {
    var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        session.startRunning()
    }
}

