//
//  PaymentRejectedView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 27/9/24.
//
import SwiftUI

struct PaymentRejectedView: View {
    var onClose: () -> Void  // Clausura para manejar el cierre de la modal

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .foregroundColor(.red)
                .frame(width: 80, height: 80)
                .padding()

            Text("Pago Rechazado")
                .font(.headline)
                .foregroundColor(.red)

            Text("El receptor ha rechazado tu solicitud de pago.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Cerrar") {
                onClose()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

