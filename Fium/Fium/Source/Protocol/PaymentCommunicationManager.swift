//
//  PaymentCommunicationManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 20/9/24.
//

import SwiftUI
import CoreNFC

protocol PaymentCommunicationManager {
    var receivedPaymentRequest: PaymentRequest? { get set }
    var selectedRole: String { get set }
    var isInPaymentView: Bool { get set }
    var statusMessage: String { get set }
    var senderState: SenderState { get }
    var receiverState: ReceiverState { get }
    var isReadyForPayment: Bool { get }  // Nueva propiedad
    var isConnected: Bool { get set }  // Nueva propiedad para verificar la conexión
    var detectedTag: NFCNDEFTag? { get set }  // Nueva propiedad
    
    // Añadimos las nuevas propiedades
    var userName: String { get set }    // Nombre del usuario
    var userIcon: UIImage? { get set }  // Foto o ícono del usuario
    
    func start()
    func stop()
    func sendRoleAndPaymentRequest(tag: NFCNDEFTag, role: String, paymentRequest: PaymentRequest?)
    func sendAcceptanceToSender()
    func updateReceiverState(_ newState: ReceiverState)
    func updateSenderState(_ newState: SenderState)
    func completePayment(amount: Double, concept: String, recipientName: String)
    func playSound(named soundName: String)
    func vibrate()
}
