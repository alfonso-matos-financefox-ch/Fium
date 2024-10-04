//
//  RedeemView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import SwiftData

struct RedeemView: View {
    @State private var offers: [Offer] = [
        Offer(id: 1, storeName: "Café Central", product: "Café Gratis", tokensRequired: 10),
        Offer(id: 2, storeName: "Librería Mundo", product: "10% Descuento", tokensRequired: 20)
    ]
    @State private var selectedOffer: Offer?
    
    
    var body: some View {
        NavigationView {
            List(offers) { offer in
                VStack(alignment: .leading) {
                    Text(offer.storeName)
                        .font(.headline)
                    Text(offer.product)
                        .font(.subheadline)
                    Text("Costo: \(offer.tokensRequired) Tokens")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    selectedOffer = offer
                }
            }
            .sheet(item: $selectedOffer) { offer in
                RedeemDetailView(offer: offer)
            }
            .navigationTitle("Canjear Tokens")
        }
    }
}

struct RedeemDetailView: View {
    let offer: Offer
    @State private var showQRCode = false
    @Environment(\.modelContext) private var context // Obtener el contexto del modelo
    
    var body: some View {
        VStack(spacing: 20) {
            Text(offer.storeName)
                .font(.largeTitle)
            Text(offer.product)
                .font(.title)
            Text("Costo: \(offer.tokensRequired) Tokens")
                .font(.title2)
                .foregroundColor(.gray)

            Button(action: {
                // Acción para generar código QR (simulado)
                showQRCode = true

                // Registrar la transacción
                let transaction = Transaction(id: UUID(), emitter: offer.storeName, receiver: "user@example.com", amount: -Double(offer.tokensRequired), concept: "Canje de \(offer.product)", date: Date(), type: .redeem, name: offer.storeName, tokensEarned: 0)

                TransactionManager.shared.addTransaction(transaction, context: context)
            }) {
                Text("Canjear")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showQRCode) {
                QRCodeView(code: "CódigoFicticio12345")
            }

            Spacer()
        }
        .padding()
    }
}

struct QRCodeView: View {
    let code: String

    var body: some View {
        VStack {
            Text("Código QR")
                .font(.largeTitle)
            Image(systemName: "qrcode")
                .resizable()
                .frame(width: 200, height: 200)
            Text(code)
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
    }
}
