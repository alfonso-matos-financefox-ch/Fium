//
//  PaymentProgressView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//

import SwiftUI

struct PaymentProgressView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    var isSendingPayment: Bool
    var isReceivingPayment: Bool
    var showPaymentSuccess: Bool

    var body: some View {
        if (isSendingPayment || isReceivingPayment) && !showPaymentSuccess {
            ProgressView(multipeerManager.isReceiver ? "Recibiendo pago..." : "Enviando pago...")
                .padding()
        }
    }
}
