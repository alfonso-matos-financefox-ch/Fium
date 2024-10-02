//
//  MockPaymentService.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 2/10/24.
//
import SwiftUI

class MockPaymentService: PaymentService {
    func processPayment(amount: Double, senderID: String, receiverID: String, completion: @escaping (Bool, String?) -> Void) {
        print("Procesando pago mock de \(amount)€ desde \(senderID) a \(receiverID)...")
        // Simulamos una respuesta exitosa o fallida con un retraso
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let success = Bool.random()
            let transactionID = success ? UUID().uuidString : nil
            completion(success, transactionID)
        }
    }
}

