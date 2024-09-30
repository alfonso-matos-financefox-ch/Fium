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
        if let amountValue = Double(amount) {
            let paymentRequest = PaymentRequest(amount: amountValue, concept: concept, senderName: multipeerManager.myPeerID.displayName)
            
            // Enviar tanto el rol como la solicitud de pago
            multipeerManager.sendPaymentRequest(paymentRequest)
            isSendingPayment = true

            // Actualizar los tokens de ambos usuarios (puedes definir la lógica para sumar tokens aquí)
            updateTokens(for: multipeerManager.discoveredPeer?.displayName ?? "Desconocido", amount: amountValue)

            sendTransactionNotification(amount: amountValue, recipient: multipeerManager.discoveredPeer?.displayName ?? "Desconocido")
            multipeerManager.updateSenderState(.paymentSent)  // Actualizamos el estado del emisor después de enviar el pago
            print("Pago enviado: \(amountValue)€ para \(concept)")
        }
    }
    
    // Función para procesar la finalización del pago para el emisor
    func processPaymentCompletionForSender() {
        print("processPaymentCompletionForSender() llamado")
        DispatchQueue.main.async {
            // Indicar que la transacción ha sido completada
            multipeerManager.updateSenderState(.paymentCompleted)
            // Calcular los tokens ganados
            let tokens = calculateTokens(for: Double(amount) ?? 0)
            tokensEarned = tokens  // Actualizar la variable de tokens en el emisor
            
            // Mostrar el check de éxito y ocultar el ProgressView
            showPaymentSuccess = true
            print("showPaymentSuccess establecido a true")
        }

        // Cerrar la pantalla automáticamente después de 3 segundos
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            // Cerrar la modal
//            presentationMode.wrappedValue.dismiss()
//        }
    }
    
    // Función para procesar el pago recibido
    func processReceivedPayment() {
        isReceivingPayment = true  // Indicamos que el receptor está procesando el pago
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            paymentSent = true
            isSendingPayment = false
            isReceivingPayment = false  // Ya no está recibiendo el pago
            
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
            showPaymentSuccess = true
            print("showPaymentSuccess establecido a true para receptor")
            // Cerrar la pantalla automáticamente después de 3 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // Cerrar la modal
                presentationMode.wrappedValue.dismiss()
            }
        }
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
}

