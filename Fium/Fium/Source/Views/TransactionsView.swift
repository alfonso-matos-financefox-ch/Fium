//
//  TransactionsView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

struct TransactionsView: View {
    @State private var transactions: [Transaction] = [
        Transaction(id: 1, name: "María Pérez", amount: -20.0, concept: "Cena", date: Date(), type: .payment),
        Transaction(id: 2, name: "Juan López", amount: 50.0, concept: "Pago recibido", date: Date(), type: .payment),
        Transaction(id: 3, name: "Café Central", amount: -10.0, concept: "Canje de café", date: Date(), type: .redeem)
    ]
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
            return transactions
        case .payment:
            return transactions.filter { $0.type == .payment }
        case .redeem:
            return transactions.filter { $0.type == .redeem }
        }
    }
}

enum TransactionType: String, CaseIterable, Identifiable {
    case all, payment, redeem

    var id: String { rawValue }
}

struct Transaction: Identifiable {
    let id: Int
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

