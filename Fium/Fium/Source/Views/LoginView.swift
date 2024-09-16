//
//  LoginView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import LocalAuthentication
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isBiometricAvailable = false
    @State private var showBiometricOption = false
    @State private var isLoggedIn = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo de Fium
                Image("fium_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                // Campos de entrada
                TextField("Correo Electrónico", text: $email)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Contraseña", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                // Botón de inicio de sesión
                Button(action: {
                    loginWithEmail()
                }) {
                    Text("Iniciar Sesión")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                // Botones de inicio de sesión con terceros
                HStack {
                    SignInButton(provider: "Google") {
                        // Acción de inicio de sesión con Google
                    }
                    SignInButton(provider: "Apple") {
                        // Acción de inicio de sesión con Apple
                    }
                    SignInButton(provider: "PayPal") {
                        loginWithPayPalMock()
                    }
                }

                // Botón de registro
                NavigationLink(destination: RegisterView()) {
                    Text("¿No tienes una cuenta? Regístrate")
                        .foregroundColor(.gray)
                }

                // Opción de autenticación biométrica
                if showBiometricOption {
                    Button(action: {
                        authenticateWithBiometrics()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Iniciar sesión con Face ID")
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Bienvenido a Fium")
            .onAppear {
                checkBiometricAvailability()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $isLoggedIn) {
                DashboardView()
            }
        }
    }

    // Funciones de autenticación
    func loginWithEmail() {
        if email.isEmpty || password.isEmpty {
            alertMessage = "Por favor, ingresa tu correo y contraseña."
            showAlert = true
        } else {
            // Simulación de inicio de sesión exitoso
            isLoggedIn = true
            showBiometricOption = true
        }
    }

    func loginWithPayPalMock() {
        // Simulación de inicio de sesión con PayPal
        isLoggedIn = true
    }

    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Autentícate para acceder a tu cuenta."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isLoggedIn = true
                    } else {
                        alertMessage = "Falló la autenticación biométrica."
                        showAlert = true
                    }
                }
            }
        } else {
            alertMessage = "La autenticación biométrica no está disponible."
            showAlert = true
        }
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}

struct SignInButton: View {
    let provider: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(provider)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(providerColor)
                .cornerRadius(10)
        }
    }

    var providerColor: Color {
        switch provider {
        case "Google":
            return Color.red
        case "Apple":
            return Color.black
        case "PayPal":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

struct RegisterView: View {
    var body: some View {
        Text("Registro de Usuario")
    }
}
