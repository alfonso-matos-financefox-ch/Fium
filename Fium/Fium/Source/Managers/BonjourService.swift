//
//  BonjourService.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import Foundation

class BonjourService: NSObject, NetServiceDelegate {
    var service: NetService?

    func publishService() {
        // Crear un servicio de prueba en el dominio local con el tipo _fium._tcp.
        self.service = NetService(domain: "local.", type: "fium-pay", name: "TestService", port: 12347)
        self.service?.delegate = self
        self.service?.publish()
        print("Iniciando la publicación de Bonjour...")
    }

    func netServiceDidPublish(_ sender: NetService) {
        // Cuando el servicio es publicado con éxito
        print("Service published: \(sender)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        // Si falla la publicación del servicio
        print("Service did not publish: \(errorDict)")
    }
}
