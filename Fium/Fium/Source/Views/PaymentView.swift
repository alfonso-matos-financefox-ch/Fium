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
    
    @State private var selectedRole: String = ""  // Rol seleccionado por el usuario (emisor o receptor)
    @State private var isReceiver = false         // Define si este usuario es receptor
    @State private var isWaitingForTransfer = false  // Controla si este dispositivo está esperando la transferencia


    var body: some View {
        VStack(spacing: 20) {
            // Selección de rol
            Picker("Selecciona tu rol", selection: $selectedRole) {
                Text("Emisor").tag("sender")
                Text("Receptor").tag("receiver")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedRole) { oldValue, newValue in
                if newValue == "receiver" {
                    isReceiver = true
                    // Enviar el rol de receptor
                    multipeerManager.sendRoleAndPaymentRequest(role: "receiver", paymentRequest: nil)
                } else if newValue == "sender" {
                    isReceiver = false
                    // Enviar el rol de emisor
                    multipeerManager.sendRoleAndPaymentRequest(role: "sender", paymentRequest: nil)
                }
            }

            if isReceiver && isWaitingForTransfer {
                Text("Esperando pago del emisor...")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("Conectado con: \(multipeerManager.discoveredPeer?.displayName ?? "Desconocido")")
                    .foregroundColor(.green)
                    .transition(.opacity)
                    .animation(.easeIn, value: multipeerManager.discoveredPeer)
            } else {
                // Campo de Monto y Concepto (solo visible si el rol es de emisor)
                TextField("Cantidad a pagar", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSendingPayment)
                
                TextField("Concepto del pago", text: $concept)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSendingPayment)
            }

            if multipeerManager.peerName != "Alfonso" {  // Asegúrate de que el valor predeterminado ha cambiado
                VStack {
                    Text("Conectado con: \(multipeerManager.peerName)")
                        .foregroundColor(.green)
                        .transition(.opacity)
                        .animation(.easeIn, value: multipeerManager.peerName)

                    Text("Ícono del peer: \(multipeerManager.peerIcon)")
                        .foregroundColor(.green)
                        .transition(.opacity)
                        .animation(.easeIn, value: multipeerManager.peerIcon)
                }
            } else {
                Text("Buscando dispositivos cercanos...")
                    .foregroundColor(.orange)
                    .transition(.opacity)
                    .animation(.easeOut, value: multipeerManager.discoveredPeer)
            }

            if isSendingPayment {
                ProgressView("Enviando pago...")
                    .padding()
            }

            // Botón para enviar solicitud de pago (solo si es emisor)
            if !isReceiver {
                Button(action: {
                    authenticateUser { success in
                        if success {
                            // Enviar solicitud preliminar de pago al receptor
                            sendPreliminaryPaymentRequest()
                        } else {
                            alertMessage = "Autenticación fallida."
                            showAlert = true
                        }
                    }
                }) {
                    Text("Enviar Solicitud de Pago")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(multipeerManager.discoveredPeer == nil || amount.isEmpty || concept.isEmpty || isSendingPayment ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(multipeerManager.discoveredPeer == nil || amount.isEmpty || concept.isEmpty || isSendingPayment)
            }

            Spacer()
            Text(multipeerManager.statusMessage)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
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
        .onChange(of: isSendingPayment) {  oldValue, newValue in
            if !newValue && paymentSent {
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
            
            // Enviar tanto el rol como la solicitud de pago
            multipeerManager.sendRoleAndPaymentRequest(role: "sender", paymentRequest: paymentRequest)
            
            isSendingPayment = true

            // Registrar la transacción localmente
            multipeerManager.statusMessage = "Registrar la transaccion localmente"
            let transaction = Transaction(id: UUID(), name: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: amountValue, concept: concept, date: Date(), type: .payment)
            TransactionManager.shared.addTransaction(transaction)

            // Actualizar los tokens de ambos usuarios (puedes definir la lógica para sumar tokens aquí)
            updateTokens(for: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: amountValue)

            sendTransactionNotification(amount: amountValue, recipient: multipeerManager.discoveredPeer?.displayName ?? "Desconocido")
        }
    }
    
    func sendPreliminaryPaymentRequest() {
        if let amountValue = Double(amount) {
            let paymentRequest = PaymentRequest(amount: amountValue, concept: concept, senderName: multipeerManager.myPeerID.displayName)
            
            // Enviar la solicitud preliminar al receptor a través de MultipeerManager
            multipeerManager.sendRoleAndPaymentRequest(role: "sender", paymentRequest: paymentRequest)
            
            isSendingPayment = true  // Indicamos que se está procesando el envío
            }
    }

    func updateTokens(for user: String, amount: Double) {
        // Actualiza la lógica de tokens, dependiendo de tu modelo
        // Por ejemplo, sumar una cantidad de tokens fija o basada en el monto
        let tokensEarned = calculateTokens(for: amount)
        
        // Aquí sumas los tokens al pagador o al receptor según sea necesario
        print("\(user) ha recibido \(tokensEarned) tokens.")
        multipeerManager.statusMessage = "\(user) ha recibido \(tokensEarned) tokens."
    }
    
    func calculateTokens(for amount: Double) -> Int {
        // Aquí puedes decidir la cantidad de tokens que ganas por cada pago
        return Int(amount / 10)  // Ejemplo: 1 token por cada 10 euros
    }
    
    func processReceivedPayment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            paymentSent = true
            isSendingPayment = false

            // Llamar a `completePayment` en MultipeerManager para registrar la transacción
            if let paymentRequest = multipeerManager.receivedPaymentRequest {
                multipeerManager.completePayment(amount: paymentRequest.amount, concept: paymentRequest.concept, recipientName: paymentRequest.senderName)
            }

            multipeerManager.receivedPaymentRequest = nil
            multipeerManager.playSound(named: "transaction_success")
            multipeerManager.statusMessage = "Transaction Success"
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
