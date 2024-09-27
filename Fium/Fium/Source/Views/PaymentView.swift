//
//  PaymentView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import LocalAuthentication

struct PaymentView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var amount = ""
    @State private var concept = ""
    @StateObject private var multipeerManager = MultipeerManager()
    @State private var showConfirmation = false
    @State private var showReceivedRequest = false
    @State private var isSendingPayment = false
    @State private var paymentSent = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSuccessCheckmark = false  // Nueva variable para mostrar la animación de éxito
    @State private var tokensEarned = 0
    @State private var showRejectionAlert = false
    
    @State private var selectedRole: String = "none"  // Rol seleccionado por el usuario (emisor o receptor)
//    @State private var isReceiver = false         // Define si este usuario es receptor
    @State private var isWaitingForTransfer = false  // Controla si este dispositivo está esperando la transferencia

    
    var body: some View {
        VStack(spacing: 20) {
            // Selección de rol
            Picker("Selecciona tu rol", selection: $selectedRole) {
                Text("Selecciona un rol").tag("none")  // Estado indefinido
                Text("Emisor").tag("sender")
                Text("Receptor").tag("receiver")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedRole) { oldValue, newValue in
                if newValue != "none" {  // Solo proceder si han seleccionado un rol
                    multipeerManager.selectedRole = newValue  // Actualiza el rol en el manager
                    multipeerManager.sendRole(newValue)  // Llama a sendRole aquí
                    if newValue == "receiver" {
                        multipeerManager.isReceiver = true
                        multipeerManager.updateReceiverState(.roleSelectedReceiver)
//                        multipeerManager.sendRoleAndPaymentRequest(role: "receiver", paymentRequest: nil)
                    } else if newValue == "sender" {
                        multipeerManager.isReceiver = false
                        multipeerManager.updateSenderState(.roleSelectedSender)
//                        multipeerManager.sendRoleAndPaymentRequest(role: "sender", paymentRequest: nil)
                    }
                }
            }.onReceive(multipeerManager.$selectedRole) { newRole in
                selectedRole = newRole  // Actualiza el picker con el nuevo rol
            }

            // Mostrar el estado del emisor
            if !multipeerManager.isReceiver {
                VStack(spacing: 10) {
                    Text("Estado del Emisor:")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(senderStateText())  // Función para mostrar el estado textual del emisor
                        .foregroundColor(.blue)
                    
                    // Campo de Monto y Concepto (solo visible si el rol es de emisor)
                    TextField("Cantidad a pagar", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isSendingPayment)
                    
                    TextField("Concepto del pago", text: $concept)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isSendingPayment)
                }
            }

            // Mostrar el estado del receptor
            if multipeerManager.isReceiver {
                VStack(spacing: 10) {
                    Text("Estado del Receptor:")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(receiverStateText())  // Función para mostrar el estado textual del receptor
                        .foregroundColor(.green)
                }
            }
            
            // Si el rol es "receiver" y ha recibido una solicitud de pago, muestra los detalles
            if multipeerManager.isReceiver && multipeerManager.receiverState == .paymentRequestReceived {
                Text("Cantidad a pagar: \(multipeerManager.receivedPaymentRequest?.amount ?? 0, specifier: "%.2f")€")
                Text("Concepto: \(multipeerManager.receivedPaymentRequest?.concept ?? "")")
                
                Button("Aceptar Pago") {
                    // El receptor acepta el pago
                    authenticateUser { success in
                        if success {
                            multipeerManager.updateReceiverState(.paymentAccepted)
                            // Envía la aceptación al emisor
                            multipeerManager.sendAcceptanceToSender()
                            processReceivedPayment()
                        } else {
                            alertMessage = "Autenticación fallida."
                            showAlert = true
                        }
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Rechazar Pago") {
                    multipeerManager.sendRejectionToSender()
                    multipeerManager.receivedPaymentRequest = nil
                    // No es necesario actualizar el estado aquí, ya se hace en sendRejectionToSender
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if multipeerManager.isReceiver && isWaitingForTransfer {
                Text("Esperando pago del emisor...")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("Conectado con: \(multipeerManager.discoveredPeer?.displayName ?? "Desconocido")")
                    .foregroundColor(.green)
                    .transition(.opacity)
                    .animation(.easeIn, value: multipeerManager.discoveredPeer)
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

            if isSendingPayment && !showSuccessCheckmark {
                ProgressView("Enviando pago...")
                    .padding()
            } else if showSuccessCheckmark {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .foregroundColor(.green)
                        .frame(width: 60, height: 60)
                        .transition(.scale)

                    Text("¡Pago realizado con éxito!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.top)

                    Text("Has ganado \(tokensEarned) tokens.")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }


            // Botón para enviar solicitud de pago (solo si es emisor)
            if !multipeerManager.isReceiver && !isSendingPayment {
                Button(action: {
                    authenticateUser { success in
                        if success {
                            // Enviar solicitud preliminar de pago al receptor
//                            sendPreliminaryPaymentRequest()
                            sendPayment()
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
                .disabled(amount.isEmpty || concept.isEmpty || isSendingPayment)  // Aquí hemos eliminado la verificación de conexión
            }

            Spacer()
            Text(multipeerManager.statusMessage)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
            
            Button(action: {
                multipeerManager.resetConnection()
            }) {
                Text("Resetear Conexión")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }

        .padding()
        .navigationTitle("Realizar Pago")
        .onAppear {
            multipeerManager.isInPaymentView = true
            multipeerManager.start()
        }
        .onDisappear {
            multipeerManager.isInPaymentView = false
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
        }.onChange(of: multipeerManager.senderState) { oldValue, newValue in
            if newValue == .paymentCompleted {
                showSuccessCheckmark = true
                processPaymentCompletionForSender()  // Manejar la finalización del pago para el emisor
                // Cerrar la pantalla automáticamente después de 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    // Cerrar la modal
                    presentationMode.wrappedValue.dismiss()
                }
            }
            if newValue == .paymentRejected {
                showRejectionAlert = true
                isSendingPayment = false  // Restablecer el estado de envío
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
        .alert(isPresented: $showRejectionAlert) {
            Alert(
                title: Text("Pago Rechazado"),
                message: Text("El receptor ha rechazado tu solicitud de pago."),
                dismissButton: .default(Text("OK")) {
                    // Opcional: Restablecer estados adicionales si es necesario
                    resetForm()
                    multipeerManager.updateSenderState(.idle)
                }
            )
        }
    }

    func sendPayment() {
        if let amountValue = Double(amount) {
            let paymentRequest = PaymentRequest(amount: amountValue, concept: concept, senderName: multipeerManager.myPeerID.displayName)
            
            // Enviar tanto el rol como la solicitud de pago
//            multipeerManager.sendRoleAndPaymentRequest(role: "sender", paymentRequest: paymentRequest)
            multipeerManager.sendPaymentRequest(paymentRequest)
            isSendingPayment = true

            // Registrar la transacción localmente
//            multipeerManager.statusMessage = "Registrar la transaccion localmente"
//            let transaction = Transaction(id: UUID(), name: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: amountValue, concept: concept, date: Date(), type: .payment)
//            TransactionManager.shared.addTransaction(transaction)

            // Actualizar los tokens de ambos usuarios (puedes definir la lógica para sumar tokens aquí)
            updateTokens(for: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: amountValue)

            sendTransactionNotification(amount: amountValue, recipient: multipeerManager.discoveredPeer?.displayName ?? "Desconocido")
            multipeerManager.updateSenderState(.paymentSent)  // Actualizamos el estado del emisor después de enviar el pago
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

    func senderStateText() -> String {
            switch multipeerManager.senderState {
            case .idle:
                return "Esperando para conectarse..."
            case .roleSelectedSender:
                return "Rol seleccionado: Emisor"
            case .waitingForPaymentApproval:
                return "Esperando que el receptor acepte el pago..."
            case .paymentAccepted:
                return "El pago ha sido aceptado por el receptor."
            case .paymentSent:
                return "El pago ha sido enviado."
            case .paymentCompleted:
                return "La transacción ha sido completada."
            case .paymentRejected:
                    return "El receptor ha rechazado el pago."  // Nuevo mensaje
            }
        }

        func receiverStateText() -> String {
            switch multipeerManager.receiverState {
            case .idle:
                return "Esperando para conectarse..."
            case .roleSelectedReceiver:
                return "Rol seleccionado: Receptor"
            case .waitingForPaymentRequest:
                return "Esperando la solicitud de pago del emisor..."
            case .paymentRequestReceived:
                return "Solicitud de pago recibida."
            case .paymentAccepted:
                return "El pago ha sido aceptado."
            case .paymentCompleted:
                return "La transacción ha sido completada."
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
    
    func processPaymentCompletionForSender() {
        // Indicar que la transacción ha sido completada
        multipeerManager.updateSenderState(.paymentCompleted)

        // Calcular los tokens ganados
        let tokens = calculateTokens(for: Double(amount) ?? 0)
        tokensEarned = tokens  // Actualizar la variable de tokens en el emisor

        // Mostrar el check de éxito y ocultar el ProgressView
        showSuccessCheckmark = true

        // Cerrar la pantalla automáticamente después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Cerrar la modal
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func processReceivedPayment() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                paymentSent = true
                isSendingPayment = false

                if let paymentRequest = multipeerManager.receivedPaymentRequest {
                    multipeerManager.completePayment(amount: paymentRequest.amount, concept: paymentRequest.concept, recipientName: paymentRequest.senderName)
                    // Simula que los tokens se calculan y se muestran
                    tokensEarned = calculateTokens(for: paymentRequest.amount)
                }

                multipeerManager.receivedPaymentRequest = nil
                multipeerManager.playSound(named: "transaction_success")
                multipeerManager.statusMessage = "Transaction Success"
                multipeerManager.vibrate()

                

                // Mostrar el check de éxito y ocultar el ProgressView
                showSuccessCheckmark = true
//                multipeerManager.updateSenderState(.paymentCompleted)  // Actualizamos el estado a completado
                
                // Cerrar la pantalla automáticamente después de 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    // Cerrar la modal
                    presentationMode.wrappedValue.dismiss()
                }
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
