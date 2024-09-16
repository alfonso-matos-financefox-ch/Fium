//
//  PaymentView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import LocalAuthentication

struct PaymentView: View {
    @State private var amount = ""
    @State private var concept = ""
    @StateObject private var multipeerManager = MultipeerManager()
    @State private var showConfirmation = false
    @State private var showReceivedRequest = false
    @State private var isSendingPayment = false
    @State private var paymentSent = false
    @State private var showAlert = false
    @State private var alertMessage = ""

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
                    .transition(.opacity)
                    .animation(.easeIn)
            } else {
                Text("Buscando dispositivos cercanos...")
                    .foregroundColor(.orange)
                    .transition(.opacity)
                    .animation(.easeOut)
            }

            if isSendingPayment {
                ProgressView("Enviando pago...")
                    .padding()
            }

            // Botón para enviar solicitud de pago
            Button(action: {
                authenticateUser { success in
                    if success {
                        sendPayment()
                    } else {
                        alertMessage = "Autenticación fallida."
                        showAlert = true
                    }
                }
            }) {
                Text("Enviar Pago")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(multipeerManager.discoveredPeer == nil || amount.isEmpty || concept.isEmpty || isSendingPayment ? Color.gray : Color.blue)
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
                    authenticateUser { success in
                        if success {
                            processReceivedPayment()
                        } else {
                            alertMessage = "Autenticación fallida."
                            showAlert = true
                        }
                    }
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func sendPayment() {
        if let amountValue = Double(amount) {
            let paymentRequest = PaymentRequest(amount: amountValue, concept: concept, senderName: multipeerManager.myPeerID.displayName)
            multipeerManager.sendPaymentRequest(paymentRequest)
            isSendingPayment = true

            // Registrar la transacción localmente
            let transaction = Transaction(id: UUID(), name: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: -amountValue, concept: concept, date: Date(), type: .payment)
            TransactionManager.shared.addTransaction(transaction)

            sendTransactionNotification(amount: amountValue, recipient: multipeerManager.discoveredPeer?.displayName ?? "Desconocido")
        }
    }

    func processReceivedPayment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            paymentSent = true
            isSendingPayment = false

            // Registrar la transacción localmente
            if let paymentRequest = multipeerManager.receivedPaymentRequest {
                let transaction = Transaction(id: UUID(), name: paymentRequest.senderName, amount: paymentRequest.amount, concept: paymentRequest.concept, date: Date(), type: .payment)
                TransactionManager.shared.addTransaction(transaction)

                sendTransactionNotification(amount: paymentRequest.amount, recipient: paymentRequest.senderName)
            }

            multipeerManager.receivedPaymentRequest = nil
            multipeerManager.playSound(named: "transaction_success")
            multipeerManager.vibrate()
        }
    }

    func resetForm() {
        amount = ""
        concept = ""
        paymentSent = false
    }

    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Confirma tu identidad para continuar."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }

    func sendTransactionNotification(amount: Double, recipient: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pago Realizado"
        content.body = "Has enviado \(String(format: "%.2f", amount))€ a \(recipient)."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
