//
//  PaymentView+Functions.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//
import SwiftUI
import LocalAuthentication
import SwiftData

extension PaymentView {
    
    // Función para enviar el pago
    func sendPayment() {
        guard let amountValue = Double(amount),
              let currentUserID = multipeerManager.currentUser?.id.uuidString, // ID del emisor (tu dispositivo)
              let peerUserID = multipeerManager.peerUser?.id.uuidString else { // ID del receptor (peer conectado)
            alertMessage = "Error: ID de Peer no disponible o cantidad inválida."
            showAlert = true
            return
        }
        
        // Crear la solicitud de pago con el UUID del emisor y del receptor
        let paymentRequest = PaymentRequest(
            senderName: multipeerManager.currentUser?.name ?? "Desconocido",
            amount: amountValue,
            concept: concept,             
            receiverID: peerUserID // UUID del peer receptor
        )
        // Actualizar en payment el amount
        amount = "\(amountValue)"
        
        // Guardamos la información temporalmente en MultipeerManager
        multipeerManager.transactionAmount = amountValue
        multipeerManager.transactionConcept = concept
        // Enviar tanto el rol como la solicitud de pago
        
        isSendingPayment = true
        paymentRequestSent = false
        
        multipeerManager.sendPaymentRequest(paymentRequest){ success in
            DispatchQueue.main.async {
                self.isSendingPayment = false
                if success {
                    self.paymentRequestSent = true
                } else {
                    self.alertMessage = "Error al enviar la solicitud de pago."
                    self.showAlert = true
                    // Opcional: Resetear campos para permitir reintentos
                    self.resetForm()
                }
            }
        }
    
        
        // Actualizar los tokens de ambos usuarios (puedes definir la lógica para sumar tokens aquí)
        updateTokens(for: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: amountValue)

        sendTransactionNotification(amount: amountValue, recipient: multipeerManager.discoveredPeer?.displayName ?? "Desconocido")
        multipeerManager.updateSenderState(.paymentRequestSent)  // Actualizamos el estado del emisor después de enviar el pago
        print("Pago enviado: \(amountValue)€ para \(concept)")
        
    }

    func resetForm() {
        amount = ""
        concept = ""
        paymentRequestSent = false
    }
    
    // Función para procesar la finalización del pago para el emisor
    func processPaymentCompletionForSender() {
        print("processPaymentCompletionForSender() llamado")
        
        DispatchQueue.main.async {
            // Calcular los tokens ganados
            let tokens = calculateTokens(for: Double(amount) ?? 0)
            tokensEarned = tokens  // Actualizar la variable de tokens en el emisor
            // Indicar que la transacción ha sido completada
//            multipeerManager.updateSenderState(.paymentCompleted) // ya ha sido cambiado el estado anteriormente
            
            
            // Mostrar el check de éxito y ocultar el ProgressView
            showPaymentSuccess = true
            print("showPaymentSuccess establecido a true para emisor")
        }

        // Cerrar la pantalla automáticamente después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Cerrar la modal
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // Función para procesar el pago recibido
//    func processReceivedPayment() {
//        isReceivingPayment = true  // Indicamos que el receptor está procesando el pago
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            paymentRequestSent = true
//            isSendingPayment = false
//            isReceivingPayment = false  // Ya no está recibiendo el pago
//            
//            if let paymentRequest = multipeerManager.receivedPaymentRequest,
//               let currentUserID = multipeerManager.currentUser?.id.uuidString,
//               let peerUserID = multipeerManager.peerUser?.id.uuidString {
//                
//                // Dependiendo del rol, definimos los IDs correctos
//                let emitterID = multipeerManager.isReceiver ? peerUserID : currentUserID
//                let receiverID = multipeerManager.isReceiver ? currentUserID : peerUserID
//
//                // Llamada a completePayment con los IDs correspondientes
//                multipeerManager.completePayment(
//                    amount: paymentRequest.amount,
//                    concept: paymentRequest.concept,
//                    recipientName: paymentRequest.senderName, // Aquí mantienes el nombre del peer
//                    emitterID: emitterID,
//                    receiverID: receiverID
//                )
//                        
//                // Simula que los tokens se calculan y se muestran
//                tokensEarned = calculateTokens(for: paymentRequest.amount)
//            }
//
//            multipeerManager.receivedPaymentRequest = nil
//            multipeerManager.playSound(named: "transaction_success")
//            multipeerManager.statusMessage = "Transaction Success"
//            multipeerManager.vibrate()
//
//            // Mostrar el check de éxito y ocultar el ProgressView
//            showPaymentSuccess = true
//            print("showPaymentSuccess establecido a true para receptor")
//            // Cerrar la pantalla automáticamente después de 3 segundos
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                // Cerrar la modal
//                presentationMode.wrappedValue.dismiss()
//            }
//        }
//    }
    
    func processReceivedPayment() {
        // Indicamos que el receptor ha aceptado la solicitud de pago, pero aún no debe mostrar la pantalla de éxito.
        isReceivingPayment = true
        paymentRequestSent = true
        isSendingPayment = false

//        if let paymentRequest = multipeerManager.receivedPaymentRequest,
//           let currentUserID = multipeerManager.currentUser?.id.uuidString,
//           let peerUserID = multipeerManager.peerUser?.id.uuidString {
//
//            // Dependiendo del rol, definimos los IDs correctos
//            let emitterID = multipeerManager.isReceiver ? peerUserID : currentUserID
//            let receiverID = multipeerManager.isReceiver ? currentUserID : peerUserID
//
//            // Aquí simplemente indicamos que el receptor ha aceptado el pago
//            // El receptor no debe llamar a completePayment aquí, ya que eso es tarea del emisor.
//            multipeerManager.sendAcceptanceToSender()
//
//            // Simula que los tokens se calcularán y se mostrarán al final, pero no aquí.
//            tokensEarned = 0 // Todavía no se han calculado, el emisor se encargará de esto.
//        }
        // El receptor envía la confirmación al emisor
            multipeerManager.sendAcceptanceToSender()
        
        // El receptor debe esperar la confirmación del emisor
        multipeerManager.receivedPaymentRequest = nil
        multipeerManager.playSound(named: "payment_received")
        multipeerManager.statusMessage = "Waiting for confirmation from sender"
        multipeerManager.vibrate()

        // No mostramos showPaymentSuccess aquí, ya que estamos esperando la confirmación del emisor.
    }


    // Función para actualizar los tokens
    func updateTokens(for user: String, amount: Double) {
        // Actualiza la lógica de tokens, dependiendo de tu modelo
        // Por ejemplo, sumar una cantidad de tokens fija o basada en el monto
        let tokensEarned = calculateTokens(for: amount)
        
        // Aquí sumas los tokens al pagador o al receptor según sea necesario
        print("\(user) ha recibido \(tokensEarned) tokens.")
        multipeerManager.statusMessage = "\(user) ha recibido \(tokensEarned) tokens."
    }
    
    // Función para calcular los tokens
    func calculateTokens(for amount: Double) -> Int {
        // Aquí puedes decidir la cantidad de tokens que ganas por cada pago
        return Int(amount / 10)  // Ejemplo: 1 token por cada 10 euros
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
}

