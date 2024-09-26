//
//  NFCManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 20/9/24.
//

import CoreNFC
import SwiftUI
import AVFAudio

class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate, PaymentCommunicationManager {

    @Published var isSessionActive = false
    @Published var message = "Esperando conexión NFC..."
    @Published var senderState: SenderState = .idle
    @Published var receiverState: ReceiverState = .idle
    @Published var statusMessage: String = ""
    @Published var nfcSession: NFCNDEFReaderSession?
    // Implementación de la propiedad requerida por PaymentCommunicationManager
    @Published var receivedPaymentRequest: PaymentRequest? = nil
    @Published var selectedRole: String = "none" // Propiedad para el rol
    @Published var isInPaymentView: Bool = false
    @Published var isConnected: Bool = false
    // Implementación de las nuevas propiedades
    @Published var userName: String = "Usuario"  // Aquí puedes inicializar con un valor por defecto o de Firebase
    @Published var userIcon: UIImage? = UIImage(named: "defaultIcon") // Puede ser un ícono por defecto
    @Published var detectedTag: NFCNDEFTag? // Añadir propiedad para almacenar el tag detectado
    
    var isSender = false
    
    static var isNFCSupported: Bool {
        return NFCNDEFReaderSession.readingAvailable
    }
    
    var isReadyForPayment: Bool {
        return isSessionActive // o cualquier condición que determine si NFC está listo
    }

    override init() {
        super.init()
    }

    // Iniciar la sesión NFC
    func start() {
        guard NFCNDEFReaderSession.readingAvailable else {
            message = "NFC no disponible"
            isConnected = false
            return
        }
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Acerca el móvil para empezar la transacción."
        nfcSession?.begin()
        isSessionActive = true
        isConnected = true  // Cuando inicie la sesión, establecer isConnected en true
    }

    // Terminar la sesión NFC
    func stop() {
        nfcSession?.invalidate()
        isSessionActive = false
        statusMessage = "Sesión NFC terminada."
        isConnected = false  // Al detener la sesión, poner isConnected en false
    }

    // Delegate - Cuando se detecta un tag NFC
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
         
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No se detectó ningún tag.")
            return
        }  // Solo trabajamos con la primera etiqueta detectada
        
        // Guardar el tag detectado
       self.detectedTag = tag
        
        session.connect(to: tag) { error in
            if let error = error {
                print("Error al conectar con la etiqueta: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Conexión fallida.")
                return
            }

            // Consultar el estado NDEF para verificar si la etiqueta está lista para escritura
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    print("Error al consultar el estado NDEF: \(error.localizedDescription)")
                    session.invalidate(errorMessage: "No se pudo consultar el estado de la etiqueta.")
                    return
                }

                guard status == .readWrite else {
                    session.invalidate(errorMessage: "El tag no está listo para escribir.")
                    return
                }

                // Definir el mensaje que deseas enviar
                 let roleData = "receiver".data(using: .utf8) ?? Data()  // Cambia "receiver" por el rol o el dato que quieras enviar
                 let payload = NFCNDEFPayload(format: .nfcWellKnown, type: Data(), identifier: Data(), payload: roleData)
                 let message = NFCNDEFMessage(records: [payload])
                
                // Llama al método para escribir en el tag
                self.writePaymentRequest(tag: tag, message: message)
            }
        }
    }

    
    // Delegate - Cuando se detectan datos NDEF (lectura)
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        if let message = messages.first {
            handleIncomingMessage(message)
        }
    }

    // Delegate - En caso de error o cancelación de la sesión
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        isSessionActive = false
        statusMessage = "Sesión NFC fallida: \(error.localizedDescription)"
        print(statusMessage)
        if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorSystemIsBusy:
                    print("El sistema NFC está ocupado. Intenta más tarde.")
                case .readerSessionInvalidationErrorUserCanceled:
                    print("La sesión NFC fue cancelada por el usuario.")
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    print("Tag leído y la sesión NFC ha sido invalidada.")
                default:
                    print("Error NFC no manejado: \(nfcError.code)")
                }
            }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("La sesión NFC se ha vuelto activa")
        self.isConnected = true
    }

    // Manejar los datos recibidos vía NFC
    func handleIncomingMessage(_ ndefMessage: NFCNDEFMessage) {
        let payload = ndefMessage.records.first?.payload
        if let data = payload {
            let receivedString = String(data: data, encoding: .utf8) ?? "Desconocido"
            print("Datos recibidos: \(receivedString)")
            
            if receivedString == "sender" {
                // Actualizar el estado del dispositivo como receptor
                DispatchQueue.main.async {
                    self.updateReceiverState(.roleSelectedReceiver)
                    print("Rol recibido: Emisor seleccionado, este dispositivo ahora es Receptor")
                }
            } else if receivedString == "receiver" {
                // Actualizar el estado del dispositivo como emisor
                DispatchQueue.main.async {
                    self.updateSenderState(.roleSelectedSender)
                    print("Rol recibido: Receptor seleccionado, este dispositivo ahora es Emisor")
                }
            }
        }
    }

    func writeRoleToTag(tag: NFCNDEFTag, message: NFCNDEFMessage, session: NFCNDEFReaderSession) {
        tag.writeNDEF(message) { error in
            if let error = error {
                print("Error al escribir en la etiqueta NFC: \(error.localizedDescription)")
                session.invalidate(errorMessage: "No se pudo escribir en la etiqueta.")
            } else {
                print("Rol enviado con éxito")
                session.alertMessage = "Rol enviado con éxito."
                session.invalidate()  // Termina la sesión
            }
        }
    }
    
    // Escribir en la etiqueta NFC
    func writePaymentRequest(tag: NFCNDEFTag, message: NFCNDEFMessage) {
        tag.writeNDEF(message) { error in
            if let error = error {
                print("Error al escribir en la etiqueta NFC: \(error.localizedDescription)")
                self.nfcSession?.invalidate(errorMessage: "No se pudo escribir en la etiqueta.")
            } else {
                print("Datos escritos con éxito en la etiqueta NFC.")
                self.nfcSession?.alertMessage = "Datos enviados con éxito."
                self.nfcSession?.invalidate()
            }
        }
    }

    
    // Implementación de enviar rol y solicitud de pago
    // Implementación de enviar rol y solicitud de pago
    func sendRoleAndPaymentRequest(tag: NFCNDEFTag, role: String, paymentRequest: PaymentRequest?) {
        if let request = paymentRequest {
            // Si hay una solicitud de pago, envíala
            sendPaymentRequest(paymentRequest: request)
        } else {
            // Si no hay PaymentRequest, envía solo el rol
            let roleData = role.data(using: .utf8) ?? Data()
            let rolePayload = NFCNDEFPayload(format: .nfcWellKnown, type: Data(), identifier: Data(), payload: roleData)
            let roleMessage = NFCNDEFMessage(records: [rolePayload])
            
            // Aquí llamamos a `writePaymentRequest` con el mensaje del rol
            writePaymentRequest(tag: tag, message: roleMessage)

            // Comienza la detección del tag para escribir
            guard let session = nfcSession else {
                print("Sesión NFC no disponible.")
                return
            }

            session.alertMessage = "Acerca el móvil para enviar el rol..."
//            session.begin()  // Esto inicia la sesión para buscar el tag NFC

            // Aquí lo manejamos en `didDetect`, reutilizando `writePaymentRequest`
        }
    }


    // Implementación de enviar aceptación al emisor
    func sendAcceptanceToSender() {
        statusMessage = "Pago aceptado y enviado al emisor."
        // Aquí enviarías los detalles al emisor usando NFC
    }

    // Implementación de completar el pago
    func completePayment(amount: Double, concept: String, recipientName: String) {
        print("Transacción completa: \(amount)€ para \(recipientName)")
        statusMessage = "Pago completado por NFC"
        playSound(named: "payment_complete")
        vibrate()
    }
    
    // Enviar datos por NFC
    func sendPaymentRequest(paymentRequest: PaymentRequest) {
        guard let session = nfcSession else {
            message = "Sesión NFC no disponible."
            return
        }

        // Crear el JSON de la solicitud de pago
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(paymentRequest)
            
            // Convertir los datos a un formato NFC Payload
            let payload = NFCNDEFPayload(format: .nfcWellKnown, type: Data(), identifier: Data(), payload: jsonData)
            let _ = NFCNDEFMessage(records: [payload])
            
            // Actualizar el mensaje de alerta en la sesión NFC
            session.alertMessage = "Acerca tu dispositivo al receptor para enviar los datos..."
            
            // Iniciar el proceso de escritura en la etiqueta NFC detectada
            session.begin()
            
            print("Pago enviado con éxito.")
                        self.updateSenderState(.waitingForPaymentApproval)

        } catch {
            print("Error al codificar la solicitud de pago: \(error.localizedDescription)")
            session.invalidate(errorMessage: "Error al procesar los datos de la solicitud de pago.")
        }
    }

    
    func updateSenderState(_ newState: SenderState) {
        DispatchQueue.main.async {
            self.senderState = newState
            print("Nuevo estado del emisor: \(newState)")
        }
    }
    
    func updateReceiverState(_ newState: ReceiverState) {
        DispatchQueue.main.async {
            self.receiverState = newState
            print("Nuevo estado del receptor: \(newState)")
        }
    }
    
    func playSound(named soundName: String) {
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.play()
            } catch {
                print("Error al reproducir sonido: \(error.localizedDescription)")
            }
        }
    }
    
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}


