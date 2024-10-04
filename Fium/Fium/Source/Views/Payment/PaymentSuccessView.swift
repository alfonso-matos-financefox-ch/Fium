//
//  PaymentSuccessView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 27/9/24.
//
import SwiftUI

struct PaymentSuccessView: View {
    var tokensEarned: Int
    var isReceiver: Bool  // Para ajustar el mensaje basado en el rol
    var onClose: () -> Void  // Clausura que se llama al cerrar la vista

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .foregroundColor(.green)
                .frame(width: 80, height: 80)
                .padding()

            Text(isReceiver ? "¡Has recibido un pago con éxito!" : "¡Pago realizado con éxito!")
                .font(.headline)
                .foregroundColor(.green)

            Text("Has ganado \(tokensEarned) tokens.")
                .font(.subheadline)
                .foregroundColor(.blue)

            Button("Cerrar") {
                onClose()  // Llama a la acción de cierre
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

