//
//  ImagePicker.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completionHandler: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(completionHandler: completionHandler)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No se necesita actualizar
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var completionHandler: (UIImage?) -> Void

        init(completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var selectedImage: UIImage?

            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }

            completionHandler(selectedImage)
        }
    }
}

