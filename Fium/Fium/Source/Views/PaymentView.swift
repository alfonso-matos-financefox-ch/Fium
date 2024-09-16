//
//  PaymentView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import AVFoundation



struct PaymentView: View {
    @State private var amount = ""
    @State private var concept = ""
    @StateObject private var multipeerManager = MultipeerManager()
    @State private var showConfirmation = false
    @State private var showReceivedRequest = false
    @State private var isSendingPayment = false
    @State private var paymentSent = false
    var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(spacing: 20) {
            // Campo de Monto
            TextField("Cantidad a pagar", text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSendingPayment)

            // Campo de Concepto
            TextField("Concepto del pago", text: $concept)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSendingPayment)

            if let peer = multipeerManager.discoveredPeer {
                Text("Conectado con: \(peer.displayName)")
                    .foregroundColor(.green)
            } else {
                Text("Buscando dispositivos cercanos...")
                    .foregroundColor(.orange)
            }

            // Botón para enviar solicitud de pago
            Button(action: {
                if let amountValue = Double(amount) {
                    let paymentRequest = PaymentRequest(amount: amountValue, concept: concept, senderName: multipeerManager.myPeerID.displayName)
                    multipeerManager.sendPaymentRequest(paymentRequest)
                    isSendingPayment = true
                }
            }) {
                Text("Enviar Pago")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(multipeerManager.discoveredPeer == nil || amount.isEmpty || concept.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(multipeerManager.discoveredPeer == nil || amount.isEmpty || concept.isEmpty || isSendingPayment)

            Spacer()
        }
        .padding()
        .navigationTitle("Realizar Pago")
        .onAppear {
            multipeerManager.start()
        }
        .onDisappear {
            multipeerManager.stop()
        }
        .onReceive(multipeerManager.$receivedPaymentRequest) { paymentRequest in
            if paymentRequest != nil {
                showReceivedRequest = true
            }
        }
        .onChange(of: isSendingPayment) { sending in
            if !sending && paymentSent {
                showConfirmation = true
                resetForm()
            }
        }
        // Alertas y hojas
        .alert(isPresented: $showReceivedRequest) {
            Alert(
                title: Text("Solicitud de Pago Recibida"),
                message: Text("De: \(multipeerManager.receivedPaymentRequest?.senderName ?? "")\nCantidad: \(multipeerManager.receivedPaymentRequest?.amount ?? 0, specifier: "%.2f")\nConcepto: \(multipeerManager.receivedPaymentRequest?.concept ?? "")"),
                primaryButton: .default(Text("Aceptar"), action: {
                    // Confirmar pago
                    processReceivedPayment()
                }),
                secondaryButton: .cancel(Text("Rechazar"), action: {
                    multipeerManager.receivedPaymentRequest = nil
                })
            )
        }
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Pago Exitoso"),
                message: Text("La transacción se ha completado con éxito."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func processReceivedPayment() {
        // Aquí puedes integrar Bizum o PayPal para procesar el pago
        // Por ahora, simulamos el procesamiento
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            paymentSent = true
            isSendingPayment = false
            multipeerManager.receivedPaymentRequest = nil
        }
    }

    func resetForm() {
        amount = ""
        concept = ""
        paymentSent = false
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
}

struct PaymentRequest: Codable {
    let amount: Double
    let concept: String
    let senderName: String
}

