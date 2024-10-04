//
//  PaymentRequestView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 27/9/24.
//
import SwiftUI

struct PaymentRequestView: View {
    var paymentRequest: PaymentRequest
    var onAccept: () -> Void
    var onReject: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Solicitud de Pago Recibida")
                .font(.headline)

            Text("Cantidad a pagar: \(paymentRequest.amount, specifier: "%.2f")€")
            Text("Concepto: \(paymentRequest.concept)")

            HStack(spacing: 20) {
                Button("Aceptar Pago") {
                    onAccept()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Rechazar Pago") {
                    onReject()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

