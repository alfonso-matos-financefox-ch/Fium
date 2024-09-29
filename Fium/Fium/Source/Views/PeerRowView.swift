//
//  PeerRowView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 27/9/24.
//
import SwiftUI

struct PeerRowView: View {
    let peerID: MCPeerID
    let peerName: String
    let peerIcon: String
    let onConnect: (MCPeerID) -> Void

    var body: some View {
        HStack {
            Image(systemName: peerIcon)
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            Text(peerName)
                .font(.headline)
            Spacer()
            Button(action: {
                onConnect(peerID)
            }) {
                Text("Conectar")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

