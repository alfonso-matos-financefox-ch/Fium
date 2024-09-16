//
//  RedeemView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

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

struct Offer: Identifiable {
    let id: Int
    let storeName: String
    let product: String
    let tokensRequired: Int
}
