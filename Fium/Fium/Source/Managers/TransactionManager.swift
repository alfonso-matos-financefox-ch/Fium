//
//  TransactionManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftData
import Foundation
import SwiftUICore

class TransactionManager: ObservableObject {
    static let shared = TransactionManager()
    @Published var transactions: [Transaction] = []

    private init() {}

    // Añadir una nueva transacción tanto al array local como a la base de datos
    func addTransaction(_ transaction: Transaction, context: ModelContext) {
        // Añadir la transacción al array local
        transactions.append(transaction)

        // Guardar la transacción en la base de datos
        do {
            context.insert(transaction) // Insertar la transacción en el contexto
            try context.save() // Guardar los cambios en la base de datos
            print("Transacción guardada: \(transaction)")
        } catch {
            print("Error al guardar la transacción: \(error)")
        }
    }

    
}
