//
//  User.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//
import Foundation
import SwiftData

@Model
class User: Identifiable {
    @Attribute(.unique) var id: UUID // El identificador único que se transmitirá
    @Attribute(.unique) var email: String
    var name: String
    var phoneNumber: String
    var profileImageData: Data?

    init(id: UUID = UUID(), email: String, name: String, phoneNumber: String, profileImageData: Data? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.phoneNumber = phoneNumber
        self.profileImageData = profileImageData
    }
}



