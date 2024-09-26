//
//  PaymentManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 20/9/24.
//

import SwiftUI
import CoreNFC

class PaymentManager: ObservableObject {
    private var bluetoothManager: BluetoothManager
    private var nfcManager: NFCManager
    private var isUsingNFC: Bool
    
    @Published var message: String = "Esperando conexión..."
    @Published var isConnected = false
    @Published var senderState: SenderState = .idle
    @Published var receiverState: ReceiverState = .idle
    
    init() {
        self.bluetoothManager = BluetoothManager()
        self.nfcManager = NFCManager()
        
        // Aquí decides si usas NFC o Bluetooth
        self.isUsingNFC = NFCNDEFReaderSession.readingAvailable
    }
    
    // Método para iniciar la conexión (NFC o Bluetooth)
    func startSession() {
        if isUsingNFC {
            nfcManager.start()
            self.observeNFCManager()
        } else {
            bluetoothManager.start()
            self.observeBluetoothManager()
        }
    }
    
    // Método para enviar solicitud de pago
    func sendPaymentRequest(amount: Double, concept: String) {
        
        if isUsingNFC {
            let paymentRequest = PaymentRequest(amount: amount, concept: concept, senderName: nfcManager.userName)
            nfcManager.sendPaymentRequest(paymentRequest: paymentRequest)
        } else {
//            bluetoothManager.sendPaymentRequest(paymentRequest: paymentRequest)
        }
    }
    
    // Observadores para sincronizar estados
    private func observeBluetoothManager() {
//        bluetoothManager.$message.assign(to: &$message)
//        bluetoothManager.$isConnected.assign(to: &$isConnected)
//        bluetoothManager.$senderState.assign(to: &$senderState)
//        bluetoothManager.$receiverState.assign(to: &$receiverState)
    }
    
    private func observeNFCManager() {
        nfcManager.$message.assign(to: &$message)
        nfcManager.$isConnected.assign(to: &$isConnected)
        nfcManager.$senderState.assign(to: &$senderState)
        nfcManager.$receiverState.assign(to: &$receiverState)
    }
    
    // Método para detener la sesión
    func stopSession() {
        if isUsingNFC {
            nfcManager.stop()
        } else {
//            bluetoothManager.stopSession()
        }
    }
}
