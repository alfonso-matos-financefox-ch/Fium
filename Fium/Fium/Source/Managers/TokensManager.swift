//
//  TokensManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 4/10/24.
//
import SwiftUI

class TokensManager {
    static let shared = TokensManager()

    // Método para calcular tokens ganados por una transacción
    func calculateTokens(for amount: Double, isSender: Bool) -> Int {
        // Lógica para diferenciar entre emisor y receptor si es necesario
        let tokenRate = isSender ? 0.1 : 0.05 // Por ejemplo, el emisor gana más tokens que el receptor
        return Int(amount * tokenRate)
    }

    // Método para redimir tokens en un comercio
    func redeemTokens(for user: User, tokens: Int) -> Bool {
        guard user.tokenBalance >= tokens else {
            print("No hay suficientes tokens para redimir.")
            return false
        }

        // Reducir los tokens del usuario
        user.tokenBalance -= tokens

        // En el futuro, aquí podemos integrar Firestore para actualizar los tokens en la nube
        // syncTokensToFirestore(user: user)

        return true
    }

    // En el futuro, este método sincronizará los tokens con Firestore
    private func syncTokensToFirestore(user: User) {
        // Aquí iría la lógica para actualizar en Firestore
    }
}

