//
//  EditProfileView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//
import SwiftUI
import SwiftData
import PhotosUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var context
    @State var user: User

    @State private var selectedImageData: Data?
    @State private var isShowingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isShowingSourceSelection = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Foto de Perfil")) {
                    HStack {
                        Spacer()
                        if let imageData = selectedImageData ?? user.profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 120, height: 120)
                                .onTapGesture {
                                    isShowingSourceSelection = true
                                }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.blue)
                                .frame(width: 120, height: 120)
                                .onTapGesture {
                                    isShowingSourceSelection = true
                                }
                        }
                        Spacer()
                    }
                }

                Section(header: Text("Información Personal")) {
                    TextField("Nombre", text: $user.name)
                    TextField("Número de Teléfono", text: $user.phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Correo Electrónico", text: .constant(user.email))
                        .disabled(true)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarItems(trailing: Button("Guardar") {
                saveProfile()
            })
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(sourceType: imagePickerSource) { image in
                    if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
                        selectedImageData = imageData
                    }
                    isShowingImagePicker = false
                }
            }
            .confirmationDialog("Selecciona una opción", isPresented: $isShowingSourceSelection, actions: {
                Button("Elegir de la Biblioteca") {
                    imagePickerSource = .photoLibrary
                    isShowingImagePicker = true
                }
                Button("Tomar una Foto") {
                    imagePickerSource = .camera
                    isShowingImagePicker = true
                }
                Button("Cancelar", role: .cancel) {}
            })
        }
    }

    func saveProfile() {
        if let imageData = selectedImageData {
            user.profileImageData = imageData
        }
        // Guardar los cambios en el contexto
        do {
            try context.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error al guardar el perfil: \(error)")
        }
    }
}


