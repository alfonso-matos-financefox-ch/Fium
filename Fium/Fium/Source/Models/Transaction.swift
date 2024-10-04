//
//  Transaction.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation
import SwiftData

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all, payment, redeem

    var id: String { rawValue }
}

enum TransactionType: String, Codable {
    case payment = "payment"
    case redeem = "redeem"
}

@Model
class Transaction: Identifiable {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var concept: String
    var date: Date
    
    var emitter: String // Correo o identificador del emisor
    var receiver: String // Correo o identificador del receptor
    var name: String // Nombre del otro usuario involucrado en la transacción (emisor o receptor)
    var tokensEarned: Int // Nuevo campo para almacenar los tokens ganados
    
    // Almacenar el valor del enum como un String
    private var transactionTypeString: String

    // Computed property para acceder al enum `TransactionType`
    var type: TransactionType {
        get {
            TransactionType(rawValue: transactionTypeString) ?? .payment
        }
        set {
            transactionTypeString = newValue.rawValue
        }
    }

    init(id: UUID = UUID(), emitter: String, receiver: String, amount: Double, concept: String, date: Date = Date(), type: TransactionType, name: String, tokensEarned: Int) {
            self.id = id
            self.emitter = emitter
            self.receiver = receiver
            self.amount = amount
            self.concept = concept
            self.date = date
            self.transactionTypeString = type.rawValue
            self.name = name
            self.tokensEarned = tokensEarned
        }
    
    var iconName: String {
        switch type {
        case .payment:
            return "arrow.up.circle"
        case .redeem:
            return "gift.circle"
        }
    }
}

    
    

