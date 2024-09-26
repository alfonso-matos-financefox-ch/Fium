//
//  PaymentRequest.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation

struct PaymentRequest: Codable, Equatable {
    let amount: Double
    let concept: String
    let senderName: String
    
    // Initializer
    init(amount: Double, concept: String, senderName: String) {
        self.amount = amount
        self.concept = concept
        self.senderName = senderName
    }
}

