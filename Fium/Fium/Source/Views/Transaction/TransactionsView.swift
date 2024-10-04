//
//  TransactionsView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    @State private var selectedFilter: TransactionFilter = .all

    var body: some View {
        NavigationView {
            VStack {
                // Filtros
                Picker("Filtro", selection: $selectedFilter) {
                    Text("Todos").tag(TransactionFilter.all)
                    Text("Pagos").tag(TransactionFilter.payment)
                    Text("Canjes").tag(TransactionFilter.redeem)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Lista de Transacciones
                List(filteredTransactions) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        currentUserEmail: multipeerManager.currentUser?.email ?? "",
                        tokensEarned: calculateTokens(for: transaction) // Calcular los tokens para la transacción
                    )
                }
            }
            .navigationTitle("Transacciones")
            .onAppear {
                print("Transacciones cargadas: \(transactions)") // Verifica si las transacciones se están cargando
            }
        }
    }

    var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all:
            return transactions
        case .payment:
            return transactions.filter { $0.type == .payment }
        case .redeem:
            return transactions.filter { $0.type == .redeem }
        }
    }

    // Función para determinar el icono basado en la dirección de la transacción
    func iconName(for transaction: Transaction) -> String {
        // Suponiendo que tienes acceso al correo del usuario actual
        guard let currentUserEmail = multipeerManager.currentUser?.email else {
            return "circle"
        }

        if transaction.emitter == currentUserEmail {
            return "arrow.up.circle"
        } else if transaction.receiver == currentUserEmail {
            return "arrow.down.circle"
        } else {
            return "circle"
        }
    }
    
    // Función para calcular los tokens ganados (basado en el amount, si es necesario)
        func calculateTokens(for transaction: Transaction) -> Int? {
            // Ejemplo: 1 token por cada 10 euros, ajusta la lógica según sea necesario
            return transaction.amount > 0 ? Int(transaction.amount / 10) : nil
        }
}
