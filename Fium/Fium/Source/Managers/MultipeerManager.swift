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
import CoreLocation
import SwiftData

class MultipeerManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let serviceType = "fium-pay"
    // Propiedad para almacenar el ModelContext
    var modelContext: ModelContext?
//    let myPeerID = MCPeerID(displayName: MultipeerManager.getDeviceModelIdentifier())
    var myPeerID: MCPeerID?
    var session: MCSession?
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?

    // Geolocalización
    var locationManager: CLLocationManager?
    @Published var currentLocation: CLLocation?
    
    @Published var discoveredPeer: MCPeerID?
    @Published var receivedPaymentRequest: PaymentRequest?
   
    @Published var isReceiver: Bool = false  // Nuevo estado para el rol del dispositivo
    @Published var isWaitingForTransfer: Bool = false  // Para controlar si está esperando una transferencia
    @Published var isSendingPayment: Bool = false  // Agregar la propiedad para gestionar el estado de envío
    
    @Published var statusMessage: String = "Buscando dispositivos cercanos..."  // Mensaje de estado
    
    @Published var senderState: SenderState = .idle
    @Published var receiverState: ReceiverState = .idle
    
    @Published var selectedRole: String = "none"  // sender o "receiver"
    @Published var isInPaymentView: Bool = false
    
    // Datos del usuario
    @Published var localPeerName: String = ""
    @Published var localPeerIcon: String = ""
    @Published var localPeerImage: UIImage?
    
    // Datos del peer conectado
    @Published var peerName: String = ""
    @Published var peerIcon: String = "person.circle.fill"
    @Published var peerImage: UIImage?
    var currentUser: User? // Usuario local (quien está usando la app)
    var peerUser: User? // Usuario peer (otro dispositivo con el que te conectas)
    var audioPlayer: AVAudioPlayer?
//    var deviceIdentifier: String
    
    @Published var transactionAmount: Double = 0.0
    @Published var transactionConcept: String = ""
    
    override init() {
        super.init()
        setupLocationManager()
    }

    // Configurar el Location Manager para obtener la geolocalización
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    // Método delegado para recibir la ubicación actualizada
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
//    func setUser(_ user: User) {
//        print("Entrando en init de multipeer manager")
//        // Usar variables temporales para evitar usar 'self' antes de super.init()
//        let name = user.name
//        let icon = "person.circle.fill" // Puedes personalizar esto si tienes un icono diferente
//        let image: UIImage? = user.profileImageData != nil ? UIImage(data: user.profileImageData!) : nil
//
//        // Asignar a las propiedades de 'self'
//        self.localPeerName = name
//        self.localPeerIcon = icon
//        self.localPeerImage = image
//
//        // Inicializar myPeerID y otros componentes de MultipeerConnectivity
//        self.myPeerID = MCPeerID(displayName: name)
//        let discoveryInfo = ["name": name]
//
//        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
//        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: MultipeerManager.serviceType)
//        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerManager.serviceType)
//        super.init()
//        
//        session.delegate = self
//        advertiser.delegate = self
//        browser.delegate = self
//    }
    
    func setUser(_ user: User) {
        // Configurar propiedades del usuario
        self.currentUser = user
        self.localPeerName = user.name
        self.localPeerIcon = "person.circle.fill" // Personaliza si tienes diferentes íconos
        self.localPeerImage = user.profileImageData != nil ? UIImage(data: user.profileImageData!) : nil

        // Inicializar componentes de MultipeerConnectivity
        self.myPeerID = MCPeerID(displayName: user.name)
        guard let myPeerID = self.myPeerID else {
                print("Error al crear myPeerID")
                return
            }
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session?.delegate = self

        let discoveryInfo = ["name": user.name, "icon": self.localPeerIcon, "id": user.id.uuidString]

        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: MultipeerManager.serviceType)
        self.advertiser?.delegate = self
        self.advertiser?.startAdvertisingPeer()

        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerManager.serviceType)
        self.browser?.delegate = self
        self.browser?.startBrowsingForPeers()
        print("MultipeerManager inicializado con el usuario local: \(user.name) y UUID: \(user.id.uuidString)")
    }
    
    // Configurar el usuario peer (usuario del otro dispositivo)
        func setPeerUser(id: UUID, name: String, profileImage: UIImage?) {
            let peerUser = User(id: id, email: "", name: name, phoneNumber: "", profileImageData: profileImage?.jpegData(compressionQuality: 0.8))
            self.peerUser = peerUser
            self.peerName = name
            self.peerIcon = "person.circle.fill"
            self.peerImage = profileImage
            print("Peer user configurado: \(name)")
        }
    
    // Método para asignar el contexto desde las vistas
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
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
        advertiser?.startAdvertisingPeer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.browser?.startBrowsingForPeers()
        }
        updateSenderState(.idle)
        updateReceiverState(.idle)
        print("Publicidad iniciada: \(String(describing: self.advertiser))")
        print("Búsqueda iniciada: \(String(describing: self.browser))")
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        print("stop session")
    }

    func sendPaymentRequest(_ paymentRequest: PaymentRequest, completion: @escaping (Bool) -> Void) {
        
        guard let session = self.session else {
            print("No hay sesión activa")
            self.statusMessage = "No hay sesión activa"
            updateSenderState(.idle)
            completion(false)
            return
        }
        if !session.connectedPeers.isEmpty {
            do {
                let data = try JSONEncoder().encode(paymentRequest)
                let message = [
                    "paymentRequest": data.base64EncodedString(),
                    "emitterID": self.currentUser?.id.uuidString ?? "", // Transmitimos el ID del emisor
                    "receiverID": paymentRequest.receiverID // ID del receptor
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: message, options: .fragmentsAllowed)
                try session.send(jsonData, toPeers: session.connectedPeers, with: .reliable)
                self.statusMessage = "Solicitud de pago enviada"
                updateSenderState(.paymentRequestSent)
                completion(true)
            } catch let error {
                print("Error sending payment request: \(error.localizedDescription)")
                self.statusMessage = "Error al enviar solicitud de pago: \(error.localizedDescription)"
                updateSenderState(.idle) // Resetear estado para permitir reintentos
                completion(false)
            }
        } else {
            print("No hay peers conectados")
            self.statusMessage = "No hay peers conectados"
            updateSenderState(.idle)
            completion(false)
        }
    }
    
    func sendRole(_ role: String) {
        let roleData = ["role": role]  // role puede ser "sender" o "receiver"
        guard let session = self.session else {
            print("No hay sesión activa para enviar el rol")
            self.statusMessage = "No hay sesión activa para enviar el rol"
            return
        }
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
            self.statusMessage = "Error al enviar el rol: \(error.localizedDescription)"

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

            guard let session = self.session else {
                print("No hay sesión activa para enviar el rol y solicitud de pago")
                self.isSendingPayment = false
                self.statusMessage = "No hay sesión activa para enviar el rol y solicitud de pago"
                return
            }
            if session.connectedPeers.isEmpty {
                print("No hay peers conectados para enviar el pago.")
                self.statusMessage = "No hay peers conectados para enviar el pago."
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
                    self.statusMessage = "Error al codificar la solicitud de pago: \(error.localizedDescription)"


                }
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: message, options: .fragmentsAllowed)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                self.statusMessage = "sendRoleAndPaymentRequest"
            } catch {
                print("Error al enviar datos: \(error)")
                self.statusMessage = "Error al enviar datos: \(error.localizedDescription)"

            }
        }
    }
    

    // Método que se ejecuta cuando el receptor acepta la solicitud de pago
    func completePayment(amount: Double, concept: String, recipientName: String, emitterID: String, receiverID: String) {
        guard let context = modelContext else {
            print("No se ha establecido el ModelContext.")
            return
        }
        print("completePayment")
        // Realiza la transacción
        DispatchQueue.main.async {
            self.statusMessage = "Antes de realizar la transacción en completePayment"
            
            
            print("Transacción completa: \(amount)€ para \(recipientName)")
            self.statusMessage = "Transacción completa: \(amount)€ para \(recipientName)"
            
            // Envía la notificación de la transacción
            self.sendTransactionNotification(amount: amount, recipient: recipientName)
            
            self.isSendingPayment = false
            self.updateSenderState(.paymentCompleted)
//            self.updateReceiverState(.paymentCompleted)
        }
    }

    func sendRejectionToSender() {
        // Crear el mensaje de rechazo
        let rejectionData: [String: Any] = [
            "status": "rejected"
        ]
        guard let session = self.session else {
            print("No hay sesión activa para enviar la notificación de rechazo")
            self.statusMessage = "No hay sesión activa para enviar la notificación de rechazo"
            return
        }
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
            self.discoveredPeer = nil
            self.receivedPaymentRequest = nil
            self.peerName = "Alfonso"
            self.peerIcon = "Icon"
            self.isReceiver = false
            self.isWaitingForTransfer = false
            self.isSendingPayment = false
            self.statusMessage = "Conexión reiniciada"
            self.senderState = .idle
            self.receiverState = .idle
            print("reset connection")
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
            "paymentRequest": paymentData,
            "emitterID": self.peerUser?.id.uuidString ?? "", // Extraer el ID del emisor desde el peerUser
            "receiverID": self.currentUser?.id.uuidString ?? "" // El ID del receptor es el del usuario local// Ahora seguro que es un String no opcional
        ]
        guard let session = self.session else {
            print("No hay sesión activa para enviar la aceptación")
            self.statusMessage = "No hay sesión activa para enviar la aceptación"
            return
        }
        
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
                self.discoveredPeer = nil  // Limpiar el peer descubierto
                
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
                        self.browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
                    } else {
                        print("No reconectar, estamos fuera de la vista de Payment.")
                        self.stop()
                    }
                } else {
                    // Intentar reconectar automáticamente al peer que se desconectó
                    print("Intentando reconectar al peer \(peerID.displayName)...")
                    self.browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
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
        guard !self.localPeerName.isEmpty else {
            print("Nombre del usuario vacío, no se puede enviar la información del perfil")
            return
        }
        var profileInfo: [String: Any] = [
                "type": "profileInfo",
                "name": self.localPeerName,
            ]

        if let imageData = self.localPeerImage?.jpegData(compressionQuality: 0.8) {
            profileInfo["imageData"] = imageData.base64EncodedString()
        } else {
            // Si no hay imagen, podemos enviar un icono por defecto
            profileInfo["icon"] = self.localPeerIcon
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: profileInfo, options: [])
            try session?.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            print("Error al enviar la información del perfil: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            if let receivedData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Receptor recibió datos: \(receivedData)")
                
                // Extraer el ID del peer del discoveryInfo y configurar el peerUser
                if let peerID = receivedData["id"] as? String,
                   let name = receivedData["name"] as? String {
                    print("Peer conectado con ID: \(peerID) y nombre: \(name)")
                    var image: UIImage? = nil
                    if let imageDataString = receivedData["imageData"] as? String,
                       let imageData = Data(base64Encoded: imageDataString) {
                        image = UIImage(data: imageData)
                    }
                    self.setPeerUser(id: UUID(uuidString: peerID)!, name: name, profileImage: image) // Suponiendo que no tienes la imagen
                }
                            
                // Manejar la información del perfil
                if let type = receivedData["type"] as? String, type == "profileInfo" {
                    let name = receivedData["name"] as? String ?? peerID.displayName
                    var icon = "person.circle.fill"
                    var image: UIImage? = nil
                    if let imageDataString = receivedData["imageData"] as? String,
                       let imageData = Data(base64Encoded: imageDataString) {
                        image = UIImage(data: imageData)
                    } else if let receivedIcon = receivedData["icon"] as? String {
                        icon = receivedIcon
                    }
                    
                    DispatchQueue.main.async {
                        self.peerName = name
                        self.peerIcon = icon
                        self.peerImage = image
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
                       let decodedData = Data(base64Encoded: paymentData),
                       let emitterID = receivedData["emitterID"] as? String, // Extraer el ID del emisor
                      let receiverID = receivedData["receiverID"] as? String { // Extraer el ID del receptor

                        do {
                            let paymentRequest = try JSONDecoder().decode(PaymentRequest.self, from: decodedData)
                            print("Solicitud de pago decodificada: \(paymentRequest)")
                            // Almacenar los valores en las propiedades publicadas
                            self.transactionAmount = paymentRequest.amount
                            self.transactionConcept = paymentRequest.concept
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
                                print("Pago aceptado por el receptor- MultipeerManager")
                                self.updateSenderState(.paymentAccepted)
                                self.statusMessage = "Pago aceptado por el receptor"
                                
                                // Asegúrate de que recibes la solicitud de pago de vuelta
                                if let paymentData = receivedData["paymentRequest"] as? String,
                                   let decodedData = Data(base64Encoded: paymentData) {
//                                    let emitterID = receivedData["emitterID"] as? String, // Extraer el ID del emisor
//                                   let receiverID = receivedData["receiverID"] as? String { // Extraer el ID del receptor
//
                                    do {
                                        let paymentRequest = try JSONDecoder().decode(PaymentRequest.self, from: decodedData)
                                        self.transactionAmount = paymentRequest.amount
                                        self.transactionConcept = paymentRequest.concept
//                                        self.statusMessage = "Entra en paymentRequest, antes de completePayment"
//                                        self.completePayment(amount: paymentRequest.amount, concept: paymentRequest.concept, recipientName: paymentRequest.senderName, emitterID: emitterID, receiverID: receiverID)
//
                                    } catch {
                                        self.statusMessage = "Error al decodificar paymentRequest"
                                        print("Error al decodificar paymentRequest: \(error)")
                                    }
                                } else {
                                    self.statusMessage = "NO Entra en paymentRequest"
                                    print("NO Entra en paymentRequest")
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
                    // 4. Confirmación del estado de la transacción enviada por el emisor
                    if self.isReceiver,  let status = receivedData["status"] as? String {
                        DispatchQueue.main.async {
                            if status == "completed" {
                                // El emisor ha confirmado que la transacción fue exitosa
                                self.updateReceiverState(.paymentCompleted)
                                print("Pago completado por el emisor")
                                // Aquí puedes registrar la transacción usando los detalles enviados por el emisor
                                if let amount = receivedData["amount"] as? Double,
                                   let concept = receivedData["concept"] as? String {
                                    // Registrar la transacción usando el monto y concepto proporcionados
                                    
                                    self.createTransaction(amount: amount, concept: concept, emitterID: receivedData["emitterID"] as? String ?? "", receiverID: receivedData["receiverID"] as? String ?? "", name: self.peerName)
                                }
                            } else if status == "failed" {
                                // El emisor ha confirmado que la transacción ha fallado
                                self.updateReceiverState(.paymentFailed)
                                print("Pago fallido según el emisor")
                               
                                print("Transacción fallida confirmada por el emisor")
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
            var peerName = peerID.displayName
            var peerIcon = "person.circle.fill"
            var peerIDValue = "" // Agregar una variable para almacenar el id
            
            if let info = info {
                // Mostrar la información personalizada (nombre e ícono) del peer
                peerName = info["name"] ?? peerID.displayName
                peerIcon = info["icon"] ?? "person.circle.fill"
                peerIDValue = info["id"] ?? ""  // Extraer el id
                print("Conectado con \(peerName) que tiene el ícono \(peerIcon) y ID \(peerIDValue)")

//                self.statusMessage = "Conectado con \(peerName) que tiene el ícono \(peerIcon)"
                DispatchQueue.main.async {
                    self.peerName = peerName
                    self.peerIcon = peerIcon
                    self.peerUser = User(id: UUID(uuidString: peerIDValue) ?? UUID(), email: "", name: peerName, phoneNumber: "")  // Configura el peerUser

                    self.discoveredPeer = peerID
                }
            }

            // Invitar al peer descubierto a la sesión
            if let session = self.session {
                do {
                    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
                    print("Invitación enviada a \(peerID.displayName)")
                }
            } else {
                print("No hay sesión activa para invitar al peer")
            }
        } else {
            print("Evitar conexión con uno mismo")
        }
            
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Peer lost: \(peerID.displayName)")
    }
    
    // Método para crear una transacción con la ubicación actual
    func createTransaction(amount: Double, concept: String, emitterID: String, receiverID: String, name: String) {
        guard let context = modelContext else { return }
        let tokensEarned = self.calculateTokens(for: amount)
        
        // Actualiza el balance de tokens del emisor y receptor
        if let emitter = self.currentUser {
            emitter.tokenBalance += tokensEarned
        }
        if let receiver = self.peerUser {
            receiver.tokenBalance += tokensEarned
        }
        let transaction = Transaction(
            id: UUID(),
            emitter: emitterID,
            receiver: receiverID,
            amount: amount,
            concept: concept,
            date: Date(),
            type: .payment,
            name: name, // Este es el nombre del otro usuario
            tokensEarned: tokensEarned, // Guardamos los tokens generados
            location: currentLocation // Pasamos la ubicación actual si está disponible
    )
        
        TransactionManager.shared.addTransaction(transaction, context: context)
        print("Transacción creada con ubicación: \(String(describing: currentLocation))")
    }
    
    
    func handlePaymentAccepted(emitterID: String, receiverID: String) {
        // Cambiar el estado a procesando
        self.updateSenderState(.processingPayment)
        guard let context = modelContext else {
            print("No se ha establecido el ModelContext.")
            return
        }
        // Usar PaymentServiceManager para realizar la transacción (mock o real)
        PaymentServiceManager.shared.processPayment(amount: self.transactionAmount, senderID: emitterID, receiverID: receiverID) { success, transactionID in
            DispatchQueue.main.async {
                if success {
                    
                    self.createTransaction(amount: self.transactionAmount, concept: self.transactionConcept, emitterID: emitterID, receiverID: receiverID, name: self.peerName)
                    self.statusMessage = "Transacción completa: \(self.transactionAmount)€ para \(self.peerUser?.name ?? "")"
                        
                    // Envía la notificación de la transacción
                    self.sendTransactionNotification(amount: self.transactionAmount, recipient: self.peerUser?.name ?? "Desconocido")
                    // Transacción completada con éxito, notificar al receptor
                    self.sendTransactionResult(success: true, emitterID: emitterID, receiverID: receiverID, amount: self.transactionAmount, concept: self.transactionConcept)
                    self.updateSenderState(.paymentCompleted)
                    print("Pago completado exitosamente con ID: \(transactionID ?? "N/A")")
                } else {
                    // Transacción fallida, notificar al receptor
                    self.sendTransactionResult(success: false, emitterID: emitterID, receiverID: receiverID, amount: self.transactionAmount, concept: self.transactionConcept)
                    self.updateSenderState(.paymentFailed)
                    print("Error al completar la transacción")
                }
            }
        }
    }
    
    func sendTransactionResult(success: Bool, emitterID: String, receiverID: String, amount: Double, concept: String) {
        guard let session = self.session else {
            print("No hay sesión activa para enviar el resultado de la transacción")
            self.statusMessage = "No hay sesión activa para enviar el resultado de la transacción"
            return
        }

        let resultData: [String: Any] = [
            "status": success ? "completed" : "failed",
            "emitterID": emitterID,
            "receiverID": receiverID,
            "amount": amount, // Incluir la cantidad de la transacción
            "concept": concept // Incluir el concepto de la transacción
        ]


        do {
            let data = try JSONSerialization.data(withJSONObject: resultData, options: .fragmentsAllowed)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            
            DispatchQueue.main.async {
                if success {
                    print("Resultado de transacción exitosa enviado al receptor")
                    self.statusMessage = "Transacción completada. Notificación enviada al receptor"
                } else {
                    print("Resultado de transacción fallida enviado al receptor")
                    self.statusMessage = "Error en la transacción. Notificación enviada al receptor"
                }
            }
        } catch let error {
            print("Error al enviar el resultado de la transacción: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.statusMessage = "Error al enviar resultado: \(error.localizedDescription)"
            }
        }
    }
    
    func calculateTokens(for amount: Double) -> Int {
        return Int(amount / 10)  // Por ejemplo, 1 token por cada 10 euros
    }

}

