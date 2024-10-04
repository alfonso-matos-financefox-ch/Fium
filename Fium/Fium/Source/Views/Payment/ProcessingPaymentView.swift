//
//  ProcessingPaymentView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 2/10/24.
//
import SwiftUI

struct ProcessingPaymentView: View {
    let isProcessing: Bool
    let onRetry: () -> Void
    let onCancel: () -> Void
    let transactionFailed: Bool

    var body: some View {
        VStack(spacing: 20) {
            if isProcessing {
                Text("Procesando tu pago...")
                    .font(.title2)
                    .padding()

                ProgressView("Por favor, espera...")
                    .padding()
            } else if transactionFailed {
                Text("La transacción ha fallado.")
                    .font(.title2)
                    .foregroundColor(.red)
                    .padding()

                Button("Reintentar") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Button("Cancelar") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .padding()
    }
}

