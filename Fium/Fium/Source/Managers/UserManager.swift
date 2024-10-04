//
//  UserManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 4/10/24.
//
import SwiftUI

class UserManager {
    static let shared = UserManager()

    // Método para actualizar los tokens de un usuario
    func updateTokens(for user: User, tokens: Int) {
        user.tokenBalance += tokens

        // En el futuro, aquí podemos integrar Firestore para actualizar la información en la nube
        // syncUserToFirestore(user: user)
    }

    // Método para sincronizar el usuario con Firestore (futuro)
    private func syncUserToFirestore(user: User) {
        // Lógica para sincronizar los datos del usuario con Firestore
    }

    // Método para obtener el saldo de tokens de un usuario
    func getTokenBalance(for user: User) -> Int {
        return user.tokenBalance
    }
}

