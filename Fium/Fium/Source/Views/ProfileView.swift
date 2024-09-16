//
//  ProfileView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

struct ProfileView: View {
    @State private var name = "Carlos García"
    @State private var email = "carlos@example.com"
    @State private var tokenBalance = 100
    @State private var invitationCount = 5
    @State private var showingEditProfile = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Foto de Perfil
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.blue)
                    .frame(width: 120, height: 120)

                // Nombre y Correo
                Text(name)
                    .font(.title)
                Text(email)
                    .foregroundColor(.gray)

                // Saldo y Invitaciones
                HStack {
                    VStack {
                        Text("Tokens")
                            .font(.headline)
                        Text("\(tokenBalance)")
                            .font(.title2)
                    }
                    Spacer()
                    VStack {
                        Text("Invitaciones")
                            .font(.headline)
                        Text("\(invitationCount)")
                            .font(.title2)
                    }
                }
                .padding()

                // Botón de Editar Perfil
                Button(action: {
                    showingEditProfile = true
                }) {
                    Text("Editar Perfil")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showingEditProfile) {
                    EditProfileView(name: $name, email: $email)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Perfil")
        }
    }
}

struct EditProfileView: View {
    @Binding var name: String
    @Binding var email: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Personal")) {
                    TextField("Nombre", text: $name)
                    TextField("Correo Electrónico", text: $email)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarItems(trailing: Button("Guardar") {
                // Acción para guardar cambios (simulada)
            })
        }
    }
}
