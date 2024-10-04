//
//  ReceiverMessageView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//

import SwiftUI

struct ReceiverMessageView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager

    var body: some View {
        VStack(spacing: 10) {
            Text("Esperando una solicitud de pago de \(multipeerManager.peerName)...")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding()
    }
}
