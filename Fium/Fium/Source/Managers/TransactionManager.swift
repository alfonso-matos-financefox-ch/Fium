//
//  TransactionManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation

class TransactionManager: ObservableObject {
    static let shared = TransactionManager()
    @Published var transactions: [Transaction] = []

    private init() {}

    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
    }
}
