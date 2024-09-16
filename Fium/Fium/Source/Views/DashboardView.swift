//
//  DashboardView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

struct DashboardView: View {
    @State private var tokenBalance = 100
    @State private var showPaymentView = false
    @State private var showTransactionsView = false
    @State private var showRedeemView = false
    @State private var showInviteView = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Saldo de Tokens
                VStack {
                    Text("Saldo de Tokens")
                        .font(.headline)
                    Text("\(tokenBalance)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // Accesos Directos
                HStack(spacing: 20) {
                    DashboardButton(iconName: "arrow.up.circle", title: "Pagar") {
                        showPaymentView = true
                    }
                    DashboardButton(iconName: "list.bullet", title: "Historial") {
                        showTransactionsView = true
                    }
                    DashboardButton(iconName: "gift.circle", title: "Canjear") {
                        showRedeemView = true
                    }
                }

                // Botón de Referidos
                Button(action: {
                    showInviteView = true
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Invitar Amigos")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Fium")
            // Navegación a otras vistas
            .sheet(isPresented: $showPaymentView) {
                PaymentView()
            }
            .sheet(isPresented: $showTransactionsView) {
                TransactionsView()
            }
            .sheet(isPresented: $showRedeemView) {
                RedeemView()
            }
            .sheet(isPresented: $showInviteView) {
                InviteView()
            }
        }
    }
}

struct DashboardButton: View {
    let iconName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text(title)
                    .foregroundColor(.primary)
            }
            .frame(width: 100, height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

