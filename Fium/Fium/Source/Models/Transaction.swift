//
//  Transaction.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation

enum TransactionType: String, CaseIterable, Identifiable, Codable {
    case all, payment, redeem

    var id: String { rawValue }
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    let name: String
    let amount: Double
    let concept: String
    let date: Date
    var type: TransactionType

    var iconName: String {
        switch type {
        case .payment:
            return "arrow.up.circle"
        case .redeem:
            return "gift.circle"
        case .all:
            return "circle"
        }
    }
}

