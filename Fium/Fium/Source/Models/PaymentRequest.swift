//
//  PaymentRequest.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation

struct PaymentRequest: Codable {
    let senderName: String
    let amount: Double
    let concept: String
    let receiverID: String // Agregamos este campo para el ID del receptor

    init(senderName: String, amount: Double, concept: String, receiverID: String) {
        self.senderName = senderName
        self.amount = amount
        self.concept = concept
        self.receiverID = receiverID // Asignamos el ID del receptor al inicializar
    }
}

