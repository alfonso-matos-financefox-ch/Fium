//
//  InviteView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

struct InviteView: View {
    @State private var qrCodeImage: UIImage?

    var userName = "JohnDoe" // Nombre del usuario autenticado
    var userID = "12345"     // ID del usuario autenticado

    var body: some View {
        VStack(spacing: 20) {
            Text("Invita a tus amigos")
                .font(.largeTitle)

            if let qrCodeImage = qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            } else {
                Text("Generando código QR...")
                    .onAppear {
                        generateQRCode()
                    }
            }

            Text("Pide a tu amigo que escanee este código para unirse a la app y obtener recompensas.")

            Spacer()
        }
        .padding()
        .navigationTitle("Invitar Amigos")
    }

    // Generar el código QR con los datos del usuario
    func generateQRCode() {
        let qrString = "\(userName)|\(userID)"
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(qrString.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let qrImage = filter.outputImage,
           let cgImage = context.createCGImage(qrImage, from: qrImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            self.qrCodeImage = uiImage
        }
    }

    // Procesar el código escaneado
    func handleScannedCode(_ code: String) {
        let components = code.split(separator: "|")
        guard components.count == 2 else { return }
        
        let scannedUserName = String(components[0])
        let scannedUserID = String(components[1])

        // Lógica para recompensar al usuario que envió la invitación
        print("Código escaneado de \(scannedUserName) con ID: \(scannedUserID)")
        
        // Registrar la invitación en el backend y otorgar tokens
        registerInvitation(forUserID: scannedUserID)
    }
    
    // Función para registrar la invitación en Firebase
    func registerInvitation(forUserID userID: String) {
//        let db = Firestore.firestore()
//        let invitationsRef = db.collection("invitations").document(userID)
//
//        invitationsRef.updateData([
//            "tokens": FieldValue.increment(Int64(10)) // Otorgar 10 tokens por invitación
//        ]) { error in
//            if let error = error {
//                print("Error al registrar la invitación: \(error.localizedDescription)")
//            } else {
//                print("Invitación registrada exitosamente y tokens otorgados")
//            }
//        }
    }
}


// Implementación de QRCodeScannerView y AVCaptureViewController permanece igual


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

