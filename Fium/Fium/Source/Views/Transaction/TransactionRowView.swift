//
//  TransactionRowView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 1/10/24.
//
import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let currentUserID: String  // UUID del usuario actual
    
    var body: some View {
        HStack {
            // Flecha e icono que indica si eres emisor o receptor
            Image(systemName: arrowDirectionIcon)
                .foregroundColor(isEmisor ? .red : .green)
                .font(.title)
            
            VStack(alignment: .leading) {
                // Concepto y fecha
                Text(transaction.concept)
                    .font(.headline)
                
                // Fecha con estilo de tiempo
                HStack {
                    Text(transaction.date, style: .time) // Hora
                    Text(transaction.date, style: .date) // Fecha
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                // Nombre del otro usuario (el emisor o receptor)
                Text(otherUserName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing) {
                // Monto de la transacción (rojo si sale dinero, verde si lo recibes)
                Text("\(transaction.amount, specifier: "%.2f") €")
                    .foregroundColor(transaction.amount < 0 ? .red : .green)
                
                // Mostrar tokens si están disponibles
                if let tokensEarned = calculateTokens() {
                    Text("\(tokensEarned) Tokens")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 10)
    }

    // Computed property para saber si soy el emisor
    private var isEmisor: Bool {
        return transaction.emitter == currentUserID
    }

    // Computed property para obtener el nombre del otro usuario
    private var otherUserName: String {
        return isEmisor ? transaction.receiver : transaction.emitter
    }

    // Computed property para definir la flecha de dirección
    private var arrowDirectionIcon: String {
        return isEmisor ? "arrow.right" : "arrow.left"
    }
    
    // Función para calcular los tokens (ajusta la lógica si es necesario)
    private func calculateTokens() -> Int? {
        return transaction.amount > 0 ? Int(transaction.amount / 10) : nil
    }
}

