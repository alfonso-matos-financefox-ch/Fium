//
//  TransactionsView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI

struct TransactionsView: View {
    @ObservedObject var transactionManager = TransactionManager.shared
    @State private var selectedFilter: TransactionType = .all

    var body: some View {
        NavigationView {
            VStack {
                // Filtros
                Picker("Filtro", selection: $selectedFilter) {
                    Text("Todos").tag(TransactionType.all)
                    Text("Pagos").tag(TransactionType.payment)
                    Text("Canjes").tag(TransactionType.redeem)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Lista de Transacciones
                List(filteredTransactions) { transaction in
                    HStack {
                        Image(systemName: transaction.iconName)
                            .foregroundColor(transaction.amount < 0 ? .red : .green)
                        VStack(alignment: .leading) {
                            Text(transaction.name)
                                .font(.headline)
                            Text(transaction.concept)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(transaction.amount, specifier: "%.2f")€")
                            .foregroundColor(transaction.amount < 0 ? .red : .green)
                    }
                }
            }
            .navigationTitle("Transacciones")
        }
    }

    var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all:
            return transactionManager.transactions
        case .payment:
            return transactionManager.transactions.filter { $0.type == .payment }
        case .redeem:
            return transactionManager.transactions.filter { $0.type == .redeem }
        }
    }
}
