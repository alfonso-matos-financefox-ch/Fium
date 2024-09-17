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
    let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    let session: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    let browser: MCNearbyServiceBrowser

    @Published var discoveredPeer: MCPeerID?
    @Published var receivedPaymentRequest: PaymentRequest?
    @Published var peerName: String = "Alfonso"  // Para almacenar el nombre del peer descubierto
    @Published var peerIcon: String = "Icon"  // Para almacenar el ícono del peer

    var audioPlayer: AVAudioPlayer?

    override init() {
        // Aquí añadimos el discoveryInfo con el nombre e ícono del usuario
        let discoveryInfo = ["name": UIDevice.current.name, "icon": "defaultIcon"]  // Puedes personalizar el ícono

        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: MultipeerManager.serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerManager.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        print("Iniciando publicidad y búsqueda de peers")
        advertiser.startAdvertisingPeer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.browser.startBrowsingForPeers()
        }
      
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
            } catch let error {
                print("Error sending payment request: \(error.localizedDescription)")
            }
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
}

// Extensiones para manejar los delegados
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Peer \(peerID.displayName) changed state: \(state.rawValue)")
        
        // Verificar si el peerID es distinto al tuyo
        if peerID != myPeerID {
            if state == .connected {
                DispatchQueue.main.async {
                    self.discoveredPeer = peerID  // Establecer peer conectado solo si no eres tú mismo
                    self.playSound(named: "connected")
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

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let paymentRequest = try JSONDecoder().decode(PaymentRequest.self, from: data)
            DispatchQueue.main.async {
                self.receivedPaymentRequest = paymentRequest
                self.discoveredPeer = peerID
                self.playSound(named: "payment_received")
                self.vibrate()
            }
        } catch let error {
            print("Error decoding payment request: \(error.localizedDescription)")
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

