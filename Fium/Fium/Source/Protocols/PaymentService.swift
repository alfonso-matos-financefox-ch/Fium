//
//  PaymentService.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 2/10/24.
//
protocol PaymentService {
    func processPayment(amount: Double, senderID: String, receiverID: String, completion: @escaping (Bool, String?) -> Void)
}

