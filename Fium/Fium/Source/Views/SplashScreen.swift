//
//  SplashScreen.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 1/10/24.
//
import SwiftUI
import SwiftData

struct SplashScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var multipeerManager: MultipeerManager
    @State private var isActive: Bool = false
    @State private var navigateToDashboard: Bool = false

    var body: some View {
        VStack {
            // Aquí puedes agregar tu logo y cualquier animación que desees
            Image(systemName: "bolt.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()

            Text("Bienvenido a Fium")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
                .padding()
        }
        .onAppear {
            // Simular una carga o realizar cualquier inicialización necesaria
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                checkUserExists()
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            if navigateToDashboard {
                DashboardView()
                    .environmentObject(multipeerManager)
            } else {
                LoginView()
                    .environmentObject(multipeerManager)
            }
        }
    }

    func checkUserExists() {
        do {
            let fetchDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(fetchDescriptor)
            if let existingUser = users.first {
                // Usuario encontrado, inicializar MultipeerManager y navegar al Dashboard
                multipeerManager.setUser(existingUser)
                navigateToDashboard = true
            } else {
                // No hay usuario, navegar al Login
                navigateToDashboard = false
            }
            isActive = true
        } catch {
            print("Error al verificar usuarios: \(error)")
            navigateToDashboard = false
            isActive = true
        }
    }
}

