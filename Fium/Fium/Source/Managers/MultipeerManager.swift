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
//    let myPeerID = MCPeerID(displayName: MultipeerManager.getDeviceModelIdentifier())
    let myPeerID: MCPeerID
    let session: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    let browser: MCNearbyServiceBrowser

//    @Published var discoveredPeer: MCPeerID?
    @Published var receivedPaymentRequest: PaymentRequest?
    @Published var peerName: String = ""  // Nombre del peer descubierto
    @Published var peerIcon: String = "person.circle.fill"  // Ícono del peer
    @Published var isReceiver: Bool = false  // Nuevo estado para el rol del dispositivo
    @Published var isWaitingForTransfer: Bool = false  // Para controlar si está esperando una transferencia
    @Published var isSendingPayment: Bool = false  // Agregar la propiedad para gestionar el estado de envío
    
    @Published var statusMessage: String = "Buscando dispositivos cercanos..."  // Mensaje de estado
    
    @Published var senderState: SenderState = .idle
    @Published var receiverState: ReceiverState = .idle
    
    @Published var selectedRole: String = "none"  // sender o "receiver"
    @Published var isInPaymentView: Bool = false
    
    @Published var localPeerName: String
    @Published var localPeerIcon: String
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeer: MCPeerID?
    
    var audioPlayer: AVAudioPlayer?
//    var deviceIdentifier: String
    override init() {
        
        statusMessage = "Iniciando publicidad y búsqueda de peers"
        
        // Aquí añadimos el discoveryInfo con el nombre e ícono del usuario
//        self.deviceIdentifier = MultipeerManager.getDeviceModelIdentifier()
        // 1. Generamos los datos mock sin usar 'self'
        let defaultNames = ["Carlos", "María", "Juan", "Ana"]
        let defaultIcons = ["person.fill", "person.circle.fill", "person.crop.circle.fill", "person.2.fill"]
        let localName = defaultNames.randomElement() ?? "Usuario"
        let localIcon = defaultIcons.randomElement() ?? "person.circle.fill"

        // 2. Asignamos los valores a las propiedades de 'self' después
        self.localPeerName = localName
        self.localPeerIcon = localIcon

        // 3. Creamos 'myPeerID' sin usar 'self'
        let myPeerID = MCPeerID(displayName: localName)
        self.myPeerID = myPeerID

        // 4. Preparamos 'discoveryInfo' sin usar 'self'
        let discoveryInfo = ["name": localName, "icon": localIcon]


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
    
    func getPeerInfo(for peerID: MCPeerID) -> (name: String, icon: String) {
        // Suponiendo que tienes un diccionario para almacenar la información de cada peer
        // Por simplicidad, usaremos el displayName y un ícono por defecto
        let name = peerID.displayName
        let icon = "person.circle.fill"
        return (name, icon)
    }

    
    func connect(to peerID: MCPeerID) {
        // Invitar al peer seleccionado a la sesión
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        DispatchQueue.main.async {
            self.connectedPeer = peerID
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
        print("stop session")
    }

    func sendPaymentRequest(_ paymentRequest: PaymentRequest) {
        if !session.connectedPeers.isEmpty {
            do {
                let data = try JSONEncoder().encode(paymentRequest)
                let message = ["paymentRequest": data.base64EncodedString()]
                let jsonData = try JSONSerialization.data(withJSONObject: message, options: .fragmentsAllowed)
                try session.send(jsonData, toPeers: session.connectedPeers, with: .reliable)
                self.statusMessage = "Solicitud de pago enviada"
                updateSenderState(.paymentSent)
            } catch let error {
                print("Error sending payment request: \(error.localizedDescription)")
                
            }
        } else {
            print("No hay peers conectados")
            self.statusMessage = "No hay peers conectados"
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
        DispatchQueue.main.async {
            var message = ["role": role]
            self.selectedRole = role // Actualiza el rol seleccionado
            print("Emisor envía datos: \(message)")
            
            // Verificar si hay peers conectados
            if self.session.connectedPeers.isEmpty {
                print("No hay peers conectados para enviar el pago.")
                self.isSendingPayment = false  // No está enviando si no hay peers
                return
            }
            // Actualizar el estado según el rol seleccionado
            if role == "sender" {
                self.updateSenderState(.waitingForPaymentApproval)
            } else if role == "receiver" {
                self.updateReceiverState(.waitingForPaymentRequest)
            }
            
            // Antes de enviar el pago
            self.isSendingPayment = true
            
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
                try self.session.send(data, toPeers: self.session.connectedPeers, with: .reliable)
                self.statusMessage = "sendRoleAndPaymentRequest"
            } catch {
                print("Error al enviar datos: \(error)")
            }
        }
    }
    

    // Método que se ejecuta cuando el receptor acepta la solicitud de pago
    func completePayment(amount: Double, concept: String, recipientName: String) {
        // Realiza la transacción
        DispatchQueue.main.async {
            self.statusMessage = "Antes de realizar la transacción en completePayment"
            let transaction = Transaction(id: UUID(), name: recipientName, amount: amount, concept: concept, date: Date(), type: .payment)
            TransactionManager.shared.addTransaction(transaction)
            
            print("Transacción completa: \(amount)€ para \(recipientName)")
            self.statusMessage = "Transacción completa: \(amount)€ para \(recipientName)"
            
            // Envía la notificación de la transacción
            self.sendTransactionNotification(amount: amount, recipient: recipientName)
            
            self.isSendingPayment = false
            self.updateSenderState(.paymentCompleted)
            self.updateReceiverState(.paymentCompleted)
        }
    }

    func sendRejectionToSender() {
        // Crear el mensaje de rechazo
        let rejectionData: [String: Any] = [
            "status": "rejected"
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: rejectionData, options: .fragmentsAllowed)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            
            print("Notificación de rechazo enviada al emisor")
            DispatchQueue.main.async {
                self.statusMessage = "Notificación de rechazo enviada al emisor"
                self.updateReceiverState(.idle)  // Actualizar el estado del receptor a idle
            }
        } catch let error {
            print("Error al enviar la notificación de rechazo: \(error)")
            DispatchQueue.main.async {
                self.statusMessage = "Error al enviar notificación de rechazo: \(error.localizedDescription)"
            }
        }
    }

    func resetConnection() {
        // Detener los servicios actuales
        self.stop()
        
        // Restablecer las variables de estado
        DispatchQueue.main.async {
//            self.discoveredPeer = nil
            self.connectedPeer = nil
            self.receivedPaymentRequest = nil
            self.peerName = "Alfonso"
            self.peerIcon = "Icon"
            self.isReceiver = false
            self.isWaitingForTransfer = false
            self.isSendingPayment = false
            self.statusMessage = "Conexión reiniciada"
            self.senderState = .idle
            self.receiverState = .idle
        }
        
        // Reiniciar los servicios
        self.start()
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
//            updateReceiverState(.paymentAccepted)
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
                self.connectedPeer = peerID
                self.isWaitingForTransfer = false
                self.isReceiver = false
                // Enviar información del perfil al peer conectado
                self.sendProfileInfo(to: peerID)
            case .connecting:
                print("Conectando con \(peerID.displayName)...")
                self.statusMessage = "Conectando con \(peerID.displayName)..."
            case .notConnected:
                print("Peer \(peerID.displayName) desconectado")
                self.statusMessage = "Peer \(peerID.displayName) desconectado"
                
                // Actualizar la interfaz para reflejar que no hay peers conectados
                self.isWaitingForTransfer = false
                self.isReceiver = false
//                self.discoveredPeer = nil  // Limpiar el peer descubierto
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                }
                // Verificar si tu dispositivo se ha desconectado
                if peerID == self.myPeerID {
                    // Si es tu propio dispositivo, reinicia la publicidad y búsqueda de peers
                    print("Tu dispositivo se ha desconectado. Reiniciando publicidad y búsqueda de peers.")
                    self.statusMessage = "Me he desconectado, procedo a reconectarme de nuevo"
                    if self.isInPaymentView {
                        print("Estamos en la vista de Payment, reiniciando publicidad y búsqueda de peers.")
                        self.restartConnection()
                    } else {
                        print("No estamos en la vista de Payment, no reiniciar conexión.")
                        self.stop()
                    }
                } else if session.connectedPeers.isEmpty { // Asegúrate de no reconectar si has salido de la vista de Payment
                    if self.isInPaymentView {
                        print("Intentando reconectar al peer \(peerID.displayName)...")
                        self.browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
                    } else {
                        print("No reconectar, estamos fuera de la vista de Payment.")
                        self.stop()
                    }
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
        self.statusMessage = "desconecto todo"
        // Reiniciar todo desde cero
        self.start() // Vuelve a empezar a anunciar y buscar peers
        self.statusMessage = "me reconecto"
    }
    
    func sendProfileInfo(to peerID: MCPeerID) {
        let profileInfo: [String: Any] = [
            "type": "profileInfo",
            "name": self.localPeerName,
            "icon": self.localPeerIcon
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: profileInfo, options: [])
            try session.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            print("Error al enviar la información del perfil: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let receivedData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Receptor recibió datos: \(receivedData)")
                // Manejar la información del perfil
                if let type = receivedData["type"] as? String, type == "profileInfo" {
                    let name = receivedData["name"] as? String ?? peerID.displayName
                    let icon = receivedData["icon"] as? String ?? "person.circle.fill"
                    
                    DispatchQueue.main.async {
                        self.peerName = name
                        self.peerIcon = icon
                    }
                }
                DispatchQueue.main.async {
                    self.statusMessage = "Datos recibidos: \(receivedData)"
                    
                    
                    // 1. Gestión de roles (emisor/receptor)
                    if let role = receivedData["role"] as? String {
                        print("Entra en role")
                        DispatchQueue.main.async {
                            self.statusMessage = "Rol recibido: \(role)"
                            
                            if role == "sender" {
                                self.selectedRole = "receiver"  // Si el otro es "sender", este será "receiver"
                                self.updateReceiverState(.roleSelectedReceiver)
                                self.isReceiver = true
                            } else if role == "receiver" {
                                self.selectedRole = "sender"  // Si el otro es "receiver", este será "sender"
                                self.updateSenderState(.roleSelectedSender)
                                self.isReceiver = false
                            }
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
                                //                            self.sendAcceptanceToSender()
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
                    
                    // 2. Gestión de la solicitud de pago (solo el receptor debe manejar esto)
                    if self.isReceiver, let paymentData = receivedData["paymentRequest"] as? String,
                       let decodedData = Data(base64Encoded: paymentData) {
                        do {
                            let paymentRequest = try JSONDecoder().decode(PaymentRequest.self, from: decodedData)
                            print("Solicitud de pago decodificada: \(paymentRequest)")
                            DispatchQueue.main.async {
                                self.receivedPaymentRequest = paymentRequest
                                self.updateReceiverState(.paymentRequestReceived)
                                self.playSound(named: "payment_received")
                                self.statusMessage = "Solicitud de pago recibida"
                                self.vibrate()
                            }
                        } catch {
                            print("Error al decodificar la solicitud de pago: \(error)")
                            DispatchQueue.main.async {
                                self.statusMessage = "Error al decodificar la solicitud de pago: \(error)"
                            }
                        }
                    } else {
                        print("No se pudo decodificar la solicitud de pago")
                        DispatchQueue.main.async {
                            self.statusMessage = "No se pudo decodificar la solicitud de pago"
                        }
                    }
                    
                    // 3. Gestión de la aceptación o rechazo del pago (solo el emisor debe manejar esto)
                    if !self.isReceiver, let status = receivedData["status"] as? String {
                        DispatchQueue.main.async {
                            if status == "accepted" {
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
                            } else if status == "rejected" {
                                print("Pago rechazado por el receptor")
                                self.updateSenderState(.paymentRejected)
                                self.statusMessage = "Pago rechazado por el receptor"
                                
                                // Opcional: Notificar al usuario
                                // Puedes agregar una notificación local o actualizar la interfaz
                            }
                        }
                        
                        
                    }
                }
            }
        } catch {
            print("Error al procesar los datos recibidos: \(error)")
            DispatchQueue.main.async {
                self.statusMessage = "Error al procesar los datos: \(error)"
            }
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
            DispatchQueue.main.async {
                if !self.discoveredPeers.contains(peerID) {
                    self.discoveredPeers.append(peerID)
                }
            }
            var peerName = peerID.displayName
            var peerIcon = "person.circle.fill"
            if let info = info {
                // Mostrar la información personalizada (nombre e ícono) del peer
                peerName = info["name"] ?? peerID.displayName
                peerIcon = info["icon"] ?? "person.circle.fill"
//                print("Conectado con \(peerName) que tiene el ícono \(peerIcon)")
//                self.statusMessage = "Conectado con \(peerName) que tiene el ícono \(peerIcon)"
                DispatchQueue.main.async {
                    self.peerName = peerName
                    self.peerIcon = peerIcon
                    self.discoveredPeer = peerID
                }
            }

            // Invitar al peer descubierto a la sesión
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            
//            DispatchQueue.main.async {
//                self.discoveredPeer = peerID  // Solo establece este peer si no es tú mismo
//            }
        } else {
            print("Evitar conexión con uno mismo")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Peer lost: \(peerID.displayName)")
        DispatchQueue.main.async {
            if let index = self.discoveredPeers.firstIndex(of: peerID) {
                self.discoveredPeers.remove(at: index)
            }
        }
    }
}

