//
//  DeviceConnectionView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 27/9/24.
//
import SwiftUI

struct DeviceConnectionView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    var onClose: () -> Void  // Acción para cerrar la modal cuando se completa la conexión

    var body: some View {
        VStack {
            HStack {
                Spacer()
                // Botón de resetear conexión
                Button(action: {
                    multipeerManager.resetConnection()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.circlepath")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.trailing)
            }

            Spacer()

            VStack {
                if multipeerManager.discoveredPeer != nil {
                    // Mostrar el icono y nombre del usuario conectado
                    Image(systemName: multipeerManager.peerIcon)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    Text(multipeerManager.peerName)
                        .font(.headline)
                        .padding(.top, 8)
                } else {
                    // Mostrar el icono por defecto y el texto "Buscando usuario..."
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    Text("Buscando usuario...")
                        .font(.headline)
                        .padding(.top, 8)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Botón "Continuar" si estamos conectados
            if multipeerManager.discoveredPeer != nil {
                Button("Continuar") {
                    onClose()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }
}
