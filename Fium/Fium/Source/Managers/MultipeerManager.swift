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

    var audioPlayer: AVAudioPlayer?

    override init() {
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerManager.serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerManager.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
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
        if state == .connected {
            DispatchQueue.main.async {
                self.discoveredPeer = peerID
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
        invitationHandler(true, session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

