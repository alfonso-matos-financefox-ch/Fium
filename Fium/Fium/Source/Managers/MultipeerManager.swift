//
//  MultipeerManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation
import MultipeerConnectivity
import AVFoundation
import AudioToolbox

class MultipeerManager: NSObject, ObservableObject {
    static let serviceType = "fium-pay"
    let myPeerID = MCPeerID(displayName: MultipeerManager.getDeviceModelIdentifier())
    let session: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    let browser: MCNearbyServiceBrowser

    @Published var discoveredPeer: MCPeerID?
    @Published var receivedPaymentRequest: PaymentRequest?
    @Published var peerName: String = "Alfonso"  // Para almacenar el nombre del peer descubierto
    @Published var peerIcon: String = "Icon"  // Para almacenar el ícono del peer
    @Published var isReceiver: Bool = false  // Nuevo estado para el rol del dispositivo
    @Published var isWaitingForTransfer: Bool = false  // Para controlar si está esperando una transferencia
    @Published var isSendingPayment: Bool = false  // Agregar la propiedad para gestionar el estado de envío
    
    @Published var statusMessage: String = "Buscando dispositivos cercanos..."  // Mensaje de estado
    
    @Published var senderState: SenderState = .idle
    @Published var receiverState: ReceiverState = .idle
    
    var audioPlayer: AVAudioPlayer?
    var deviceIdentifier: String
    override init() {
        
        statusMessage = "Iniciando publicidad y búsqueda de peers"
        
        // Aquí añadimos el discoveryInfo con el nombre e ícono del usuario
        self.deviceIdentifier = MultipeerManager.getDeviceModelIdentifier()
        let discoveryInfo = ["name": deviceIdentifier, "icon": "defaultIcon"]  // Puedes personalizar el ícono

        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: MultipeerManager.serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerManager.serviceType)
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
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
    
    static func getDeviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.compactMap { element in
            guard let value = element.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
        return identifier
    }
    
    func start() {
        print("Iniciando publicidad y búsqueda de peers")
        advertiser.startAdvertisingPeer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.browser.startBrowsingForPeers()
        }
        updateSenderState(.idle)
        updateReceiverState(.idle)
        print("Publicidad iniciada: \(self.advertiser)")
        print("Búsqueda iniciada: \(self.browser)")
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    func sendPaymentRequest(_ paymentRequest: PaymentRequest) {
        if !session.connectedPeers.isEmpty {
            do {
                let data = try JSONEncoder().encode(paymentRequest)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                playSound(named: "payment_sent")
                self.statusMessage = "payment sent"
                updateSenderState(.paymentSent)
            } catch let error {
                print("Error sending payment request: \(error.localizedDescription)")
                
            }
        } else {
            print("No hay peers conectados")
        }
    }
    
    func sendRole(_ role: String) {
        let roleData = ["role": role]  // role puede ser "sender" o "receiver"
        do {
            let data = try JSONSerialization.data(withJSONObject: roleData, options: .fragmentsAllowed)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            self.statusMessage = "sendRole"
            if role == "sender" {
                updateSenderState(.roleSelectedSender)
            } else {
                updateReceiverState(.roleSelectedReceiver)
            }
        } catch let error {
            print("Error al enviar el rol: \(error)")
        }
    }

    func playSound(named soundName: String) {
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch let error {
                print("Error al reproducir sonido: \(error.localizedDescription)")
            }
        }
    }

    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func sendRoleAndPaymentRequest(role: String, paymentRequest: PaymentRequest?) {
        var message = ["role": role]
        
        // Verificar si hay peers conectados
       if session.connectedPeers.isEmpty {
           print("No hay peers conectados para enviar el pago.")
           isSendingPayment = false  // No está enviando si no hay peers
           return
       }
        // Actualizar el estado según el rol seleccionado
        if role == "sender" {
            updateSenderState(.waitingForPaymentApproval)
        } else if role == "receiver" {
            updateReceiverState(.waitingForPaymentRequest)
        }
        
        // Antes de enviar el pago
        isSendingPayment = true
        
        if let request = paymentRequest {
            do {
                let paymentData = try JSONEncoder().encode(request)
                let paymentString = paymentData.base64EncodedString()  // Convertir a String en Base64
                message["paymentRequest"] = paymentString  // Asignar como cadena
                print("Envío rol: \(paymentString)")
                self.statusMessage = "Envío rol: \(paymentString)"
            } catch {
                print("Error al codificar la solicitud de pago: \(error)")
            }
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: .fragmentsAllowed)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            self.statusMessage = "sendRoleAndPaymentRequest"
        } catch {
            print("Error al enviar datos: \(error)")
        }
    }
    
    

    // Método que se ejecuta cuando el receptor acepta la solicitud de pago
    func completePayment(amount: Double, concept: String, recipientName: String) {
        // Realiza la transacción
        self.statusMessage = "Antes de realizar la transacción en completePayment"
        let transaction = Transaction(id: UUID(), name: recipientName, amount: amount, concept: concept, date: Date(), type: .payment)
        TransactionManager.shared.addTransaction(transaction)
        
        print("Transacción completa: \(amount)€ para \(recipientName)")
        self.statusMessage = "Transacción completa: \(amount)€ para \(recipientName)"

        // Envía la notificación de la transacción
        sendTransactionNotification(amount: amount, recipient: recipientName)
        
        isSendingPayment = false
        updateSenderState(.paymentCompleted)
        updateReceiverState(.paymentCompleted)
    }

    
    func sendTransactionNotification(amount: Double, recipient: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pago Realizado"
        content.body = "Has enviado \(amount)€ a \(recipient)."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
        self.statusMessage = "sendTransactionNotification"
    }
    
    func sendAcceptanceToSender() {
        self.statusMessage = "sendAcceptanceToSender"
        guard let paymentRequest = self.receivedPaymentRequest else {
            print("No payment request found in receiver")
            self.statusMessage = "No payment request found in receiver"
            return
        }
        
        // Codifica el paymentRequest y envíalo de vuelta al emisor
        let paymentData = (try? JSONEncoder().encode(paymentRequest).base64EncodedString()) ?? ""
        
        let acceptanceData: [String: Any] = [
            "status": "accepted",
            "paymentRequest": paymentData  // Ahora seguro que es un String no opcional
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: acceptanceData, options: .fragmentsAllowed)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            
            print("Solicitud de pago aceptada y enviada al emisor con detalles de la transacción")
            self.statusMessage = "Solicitud de pago aceptada y detalles enviados"
            updateReceiverState(.paymentAccepted)
        } catch let error {
            print("Error al enviar la aceptación: \(error)")
            self.statusMessage = "Error al enviar aceptación: \(error.localizedDescription)"
        }
    }

}

// Extensiones para manejar los delegados
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Peer \(peerID.displayName) changed state: \(state.rawValue)")
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Peer \(peerID.displayName) conectado")
                self.statusMessage = "Peer \(peerID.displayName) conectado"
                self.isWaitingForTransfer = false
                self.isReceiver = false
            case .connecting:
                print("Conectando con \(peerID.displayName)...")
                self.statusMessage = "Conectando con \(peerID.displayName)..."
            case .notConnected:
                print("Peer \(peerID.displayName) desconectado")
                self.statusMessage = "Peer \(peerID.displayName) desconectado"
                
                // Actualizar la interfaz para reflejar que no hay peers conectados
                self.isWaitingForTransfer = false
                self.isReceiver = false
                self.discoveredPeer = nil  // Limpiar el peer descubierto
                
                // Verificar si tu dispositivo se ha desconectado
                if peerID == self.myPeerID {
                    // Si es tu propio dispositivo, reinicia la publicidad y búsqueda de peers
                    print("Tu dispositivo se ha desconectado. Reiniciando publicidad y búsqueda de peers.")
                    self.restartConnection()
                } else {
                    // Intentar reconectar automáticamente al peer que se desconectó
                    print("Intentando reconectar al peer \(peerID.displayName)...")
                    self.browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
                }
                
            @unknown default:
                fatalError("Estado desconocido de la sesión")
            }
        }
        // Verificar si el peerID es distinto al tuyo
        if peerID != myPeerID {
            if state == .connected {
                DispatchQueue.main.async {
                    self.discoveredPeer = peerID  // Establecer peer conectado solo si no eres tú mismo
                    self.playSound(named: "connected")
                    self.statusMessage = "connected"
                    self.vibrate()
                }
            } else if state == .notConnected {
                DispatchQueue.main.async {
                    if self.discoveredPeer == peerID {
                        self.discoveredPeer = nil
                    }
                }
            }
        } else {
            print("No debe conectar consigo mismo.")
        }
    }

    func restartConnection() {
        // Detener servicios actuales
        self.stop() // Este es tu método que detiene advertiser, browser y desconecta la sesión

        // Reiniciar todo desde cero
        self.start() // Vuelve a empezar a anunciar y buscar peers
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let receivedData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Entra en didReceive: \(receivedData)")
                DispatchQueue.main.async {
                    self.statusMessage = "Entra en didReceive: \(receivedData)"
                }
                
                // 1. Gestión de roles (emisor/receptor)
                if let role = receivedData["role"] as? String {
                    print("Entra en role")
                    DispatchQueue.main.async {
                        self.statusMessage = "Entra en role"
                    }
                    DispatchQueue.main.async {
                        if role == "sender" {
                            // El receptor espera la solicitud de pago
                            self.updateReceiverState(.waitingForPaymentRequest)
                            print("Role sender")
                            self.statusMessage = "Role sender"
                            // Si el otro dispositivo es el emisor, este dispositivo será el receptor
                            self.isReceiver = true
                            self.isWaitingForTransfer = true  // Mostrar la interfaz de espera
                            // Ahora el receptor puede aceptar la solicitud
                            // Si acepta, llamamos a una función para enviar la aceptación de vuelta al emisor
                            self.sendAcceptanceToSender()
                        } else if role == "receiver" {
                            self.updateSenderState(.waitingForPaymentApproval)
                            print("role receiver")
                            self.statusMessage = "role receiver"
                            // Si el otro dispositivo es el receptor, este dispositivo es el emisor
                            self.isReceiver = false
                            self.isWaitingForTransfer = false  // Mostrar la interfaz de envío
                        }
                    }
                }
                
                // 2. Gestión de la solicitud de pago (si es receptor)
                if let paymentData = receivedData["paymentRequest"] as? String,
                   let decodedData = Data(base64Encoded: paymentData) {
                    let paymentRequest = try JSONDecoder().decode(PaymentRequest.self, from: decodedData)
                    print("Entra en paymentData")
                    updateReceiverState(.paymentRequestReceived)
                    DispatchQueue.main.async {
                        self.statusMessage = "Entra en paymentData"
                    }
                    DispatchQueue.main.async {
                        self.receivedPaymentRequest = paymentRequest
                        self.discoveredPeer = peerID
                        self.playSound(named: "payment_received")
                        self.statusMessage = "payment_received"
                        self.vibrate()
                    }
                }
                
                // 3. Gestión de la aceptación de pago
                if let status = receivedData["status"] as? String, status == "accepted" {
                    DispatchQueue.main.async {
                        print("Pago aceptado por el receptor")
                        self.updateSenderState(.paymentAccepted)
                        self.statusMessage = "Pago aceptado por el receptor"
                        
                        // Asegúrate de que recibes la solicitud de pago de vuelta
                        if let paymentData = receivedData["paymentRequest"] as? String,
                           let decodedData = Data(base64Encoded: paymentData) {
                            do {
                                let paymentRequest = try JSONDecoder().decode(PaymentRequest.self, from: decodedData)
                                self.statusMessage = "Entra en paymentRequest, antes de completePayment"
                                self.completePayment(amount: paymentRequest.amount, concept: paymentRequest.concept, recipientName: paymentRequest.senderName)
                            } catch {
                                self.statusMessage = "Error al decodificar paymentRequest"
                                print("Error al decodificar paymentRequest: \(error)")
                            }
                        } else {
                            self.statusMessage = "NO Entra en paymentRequest"
                        }
                    }
                }
            }
        } catch {
            print("Error al procesar los datos recibidos: \(error)")
        }
    }


    // Métodos no utilizados
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Invitation received from: \(peerID.displayName)")
        self.statusMessage = "Invitation received from: \(peerID.displayName)"
        invitationHandler(true, session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Peer found: \(peerID.displayName)")
       
        // Verifica que no estás conectándote a ti mismo
        if peerID != myPeerID {
            if let info = info {
                // Mostrar la información personalizada (nombre e ícono) del peer
                let peerName = info["name"] ?? "Desconocido"
                let peerIcon = info["icon"] ?? "defaultIcon"
                print("Conectado con \(peerName) que tiene el ícono \(peerIcon)")
                self.statusMessage = "Conectado con \(peerName) que tiene el ícono \(peerIcon)"
                DispatchQueue.main.async {
                    self.peerName = peerName
                    self.peerIcon = peerIcon
                }
            }

            // Invitar al peer descubierto a la sesión
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            
            DispatchQueue.main.async {
                self.discoveredPeer = peerID  // Solo establece este peer si no es tú mismo
            }
        } else {
            print("Evitar conexión con uno mismo")
        }
        }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Peer lost: \(peerID.displayName)")
    }
}

