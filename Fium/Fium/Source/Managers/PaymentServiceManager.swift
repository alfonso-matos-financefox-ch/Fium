//
//  PaymentServiceManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 2/10/24.
//
class PaymentServiceManager {
    
    static let shared = PaymentServiceManager()
    
    private var service: PaymentService
    
    private init() {
        // Inicialmente se utiliza el servicio mock
        self.service = MockPaymentService()
    }
    
    // Método para cambiar el servicio de pago (en el futuro podemos cambiar a PayPal, Bizum, etc.)
    func setPaymentService(_ service: PaymentService) {
        self.service = service
    }
    
    // Método centralizado para procesar los pagos
    func processPayment(amount: Double, senderID: String, receiverID: String, completion: @escaping (Bool, String?) -> Void) {
        service.processPayment(amount: amount, senderID: senderID, receiverID: receiverID, completion: completion)
    }
}

