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
    
    @State private var isAnimating = false  // Estado para la animación
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                // Perfil del usuario actual (izquierda)
                VStack {
                    Image(systemName: multipeerManager.localPeerIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    Text(multipeerManager.localPeerName)
                        .font(.headline)
                }
                
                // Línea que conecta ambos perfiles
                ZStack {
                    // Línea base
                    Rectangle()
                        .fill(multipeerManager.connectedPeer != nil ? Color.green : Color.orange)
                        .frame(width: 100, height: 2)
                    
                    // Animación mientras busca
                    if multipeerManager.connectedPeer == nil {
                        // Línea intermitente
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 100, height: 2)
                            .opacity(isAnimating ? 0.2 : 1.0)
                            .animation(.linear(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
                            .onAppear {
                                isAnimating = true
                            }
                    }
                }
                
                // Añadir el checkmark debajo de la línea cuando esté conectado
                if multipeerManager.connectedPeer != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.green)
                        .padding(.top, 5)
                }
                
                // Perfil del otro usuario (derecha)
                VStack {
                    if let discoveredPeer = multipeerManager.connectedPeer {
                        Image(systemName: multipeerManager.peerIcon)  // Usa el icono del peer
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.green)
                        Text(multipeerManager.peerName)
                            .font(.headline)
                    } else {
                        // Mostrar icono por defecto mientras se busca
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        Text("Buscando...")
                            .font(.headline)
                    }
                }
            }
            
            Spacer()
            
            // Botón para cerrar la modal si es necesario
            if multipeerManager.connectedPeer != nil {
                Button("Continuar") {
                    onClose()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            Button(action: {
                multipeerManager.resetConnection()
            }) {
                Text("Resetear Conexión")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding()
            Spacer()
        }.onAppear {
            if multipeerManager.discoveredPeers.count == 1 {
                // Conectar automáticamente al único peer disponible
                if let peerID = multipeerManager.discoveredPeers.first {
                    multipeerManager.connect(to: peerID)
                    onClose()
                }
            }
        }
        .padding()
    }
}
