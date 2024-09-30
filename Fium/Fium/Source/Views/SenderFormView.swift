//
//  SenderFormView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//

import SwiftUI

struct SenderFormView: View {
    @Binding var amount: String
    @Binding var concept: String
    @Binding var isSendingPayment: Bool
    @ObservedObject var multipeerManager: MultipeerManager
    var authenticateAction: (@escaping (Bool) -> Void) -> Void
    var sendPaymentAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            TextField("Cantidad a pagar", text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSendingPayment)

            TextField("Concepto del pago", text: $concept)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSendingPayment)

            Button(action: {
                authenticateAction { success in
                    if success {
                        sendPaymentAction()
                    } else {
                        // Manejar la autenticación fallida en la vista principal
                    }
                }
            }) {
                Text("Enviar Solicitud de Pago")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(amount.isEmpty || concept.isEmpty || isSendingPayment ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(amount.isEmpty || concept.isEmpty || isSendingPayment)
        }
        .padding()
    }
}
