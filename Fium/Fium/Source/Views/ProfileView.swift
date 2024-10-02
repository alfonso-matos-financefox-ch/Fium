//
//  ProfileView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [User]  // Usamos @Query para obtener el usuario
    @State private var showingEditProfile = false
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Foto de Perfil
                if let imageData = users.first?.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 120, height: 120)
                        .onTapGesture {
                            showingEditProfile = true
                        }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.blue)
                        .frame(width: 120, height: 120)
                        .onTapGesture {
                            showingEditProfile = true
                        }
                }

                // Nombre y Correo
                Text(users.first?.name ?? "Nombre no disponible")
                    .font(.title)
                Text(users.first?.email ?? "Email no disponible")
                    .foregroundColor(.gray)

                // Saldo y otras propiedades
                // Aquí puedes mostrar otras propiedades si lo deseas

                Spacer()
            }
            .padding()
            .navigationTitle("Perfil")
            .sheet(isPresented: $showingEditProfile) {
                if let user = users.first {
                    EditProfileView(user: user)
                } else {
                    EmptyView()

                }

            }
            .onAppear {
                // Si no hay usuario, creamos uno por defecto
                if users.isEmpty {
                    let newUser = User(email: "usuario@example.com", name: "Nombre Apellido", phoneNumber: "")
                    context.insert(newUser)
                    do {
                        try context.save()
                    } catch {
                        print("Error al crear el usuario: \(error)")
                    }
                }
            }
        }
    }
}
