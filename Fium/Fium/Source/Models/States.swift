//
//  States.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 18/9/24.
//

import Foundation

enum SenderState {
    case idle                  // El emisor está esperando conectarse
    case roleSelectedSender    // El emisor ha seleccionado su rol
    case waitingForPaymentApproval  // Esperando que el receptor acepte la solicitud de pago
    case paymentAccepted       // El receptor ha aceptado la solicitud de pago
    case paymentSent           // El pago ha sido enviado
    case paymentCompleted      // La transacción ha sido completada
    case paymentRejected
}

enum ReceiverState {
    case idle                  // El receptor está esperando conectarse
    case roleSelectedReceiver  // El receptor ha seleccionado su rol
    case waitingForPaymentRequest  // Esperando la solicitud de pago del emisor
    case paymentRequestReceived    // El receptor ha recibido la solicitud de pago
    case paymentAccepted       // El receptor ha aceptado la solicitud de pago
    case paymentCompleted      // La transacción ha sido completada
}

