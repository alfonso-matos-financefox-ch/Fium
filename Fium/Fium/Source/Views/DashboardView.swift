//
//  DashboardView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import SwiftData

import SwiftUI

enum ActiveSheet: Identifiable {
    case payment
    case profile
    case transactions
    case redeem
    case invite

    var id: Int {
        hashValue
    }
    
    var detents: Set<PresentationDetent> {
            switch self {
            case .payment:
                return [.fraction(0.5)]
            default:
                return [.large]
            }
        }
}

struct DashboardView: View {
    @Query(sort: \User.name, order: .forward) var users: [User]
    @EnvironmentObject var multipeerManager: MultipeerManager
    @ObservedObject var transactionManager = TransactionManager.shared
    @State private var showPaymentView = false
    @State private var showTransactionsView = false
    @State private var showRedeemView = false
    @State private var showInviteView = false
    @State private var showProfileView = false
    @Environment(\.modelContext) private var context
    @State private var activeSheet: ActiveSheet? = nil
    
    var tokenBalance: Double {
        transactionManager.transactions.reduce(100) { $0 + $1.amount }
    }

    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Saldo de Tokens
                VStack {
                    Text("Saldo de Tokens")
                        .font(.headline)
                    Text("\(tokenBalance, specifier: "%.2f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // Accesos Directos
                HStack(spacing: 20) {
                    DashboardButton(iconName: "arrow.up.circle", title: "Pagar") {
//                        showPaymentView = true
                        if users.isEmpty {
                            activeSheet = .profile
                        } else {
                            activeSheet = .payment
                        }
                    }
                    DashboardButton(iconName: "list.bullet", title: "Historial") {
//                        showTransactionsView = true
                        activeSheet = .transactions
                    }
                    DashboardButton(iconName: "gift.circle", title: "Canjear") {
                        activeSheet = .redeem
//                        showRedeemView = true
                    }
                }

                // Botón de Referidos
                Button(action: {
                    activeSheet = .invite

//                    showInviteView = true
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

                // Botón de Perfil
                Button(action: {
                    showProfileView = true
                }) {
                    Text("Perfil")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showProfileView) {
                    ProfileView()
                        .onDisappear {
                            if let user = users.first {
                                multipeerManager.setUser(user)
                            }
                        }
                        .environmentObject(multipeerManager) // Pasar environmentObject
                }
            }
            .padding()
            .navigationTitle("Fium")
            // Navegación a otras vistas
            .sheet(item: $activeSheet) { item in
                switch item {
                case .payment:
                    if let user = users.first {
                        PaymentView()
                            .presentationDetents(item.detents)
                            .environmentObject(multipeerManager) // Pasar environmentObject
                    } else {
                        // Redirigir al perfil si no hay usuario
                        ProfileView()
                            .onDisappear {
                                if let user = users.first {
                                    multipeerManager.setUser(user)
                                }
                            }
                            .environmentObject(multipeerManager) // Pasar environmentObject
                    }
                case .profile:
                    ProfileView()
                        .onDisappear {
                        if let user = users.first {
                            multipeerManager.setUser(user)
                        }
                    }.environmentObject(multipeerManager) // Pasar environmentObject
                case .transactions:
                    TransactionsView().environmentObject(multipeerManager) // Pasar environmentObject
                case .redeem:
                    RedeemView().environmentObject(multipeerManager) // Pasar environmentObject
                case .invite:
                    InviteView().environmentObject(multipeerManager) // Pasar environmentObject
                }
            }.onAppear {
                // Establecer el contexto en el multipeerManager
                multipeerManager.setModelContext(context)
                if users.isEmpty {
                    activeSheet = .profile
                } else if let existingUser = users.first {
                    multipeerManager.setUser(existingUser) //TODO: REMOVE THIS
                }
            }
//            .disabled(users.isEmpty)
//            .sheet(isPresented: $showPaymentView) {
//                if let user = users.first {
//                    let manager = MultipeerManager(user: user)
//                    PaymentView(multipeerManager: manager)
//                } else {
//                    Text("No se encontró el usuario.")
//                }
//            }
//            .sheet(isPresented: $showTransactionsView) {
//                TransactionsView()
//            }
//            .sheet(isPresented: $showRedeemView) {
//                RedeemView()
//            }
//            .sheet(isPresented: $showInviteView) {
//                InviteView()
//            }
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
