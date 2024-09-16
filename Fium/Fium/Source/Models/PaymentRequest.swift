//
//  PaymentRequest.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation

struct PaymentRequest: Codable {
    let amount: Double
    let concept: String
    let senderName: String
}

