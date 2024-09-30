//
//  PaymentView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//
import SwiftUI

import LocalAuthentication
import SwiftData

struct PaymentView: View {
    
    @Environment(\.modelContext) private var context
    @Query private var users: [User]  // Obtenemos el usuario
    
    @Environment(\.presentationMode) var presentationMode
    @State var amount = ""
    @State var concept = ""
    @ObservedObject var multipeerManager: MultipeerManager
    @State var showConfirmation = false
    @State var showReceivedRequest = false
    @State var isSendingPayment = false
    @State var paymentSent = false
    @State var showAlert = false
    @State var alertMessage = ""
    @State var tokensEarned = 0
    @State var showRejectionAlert = false
    
    @State var selectedRole: String = "none"  // Rol seleccionado por el usuario (emisor o receptor)
    @State var isWaitingForTransfer = false  // Controla si este dispositivo está esperando la transferencia
    @State var isReceivingPayment = false  // Nuevo estado para el receptor
    @State var showPaymentSuccess = false
    @State var showDeviceConnection = true  // Mostrar la modal al iniciar
    
    var body: some View {
        VStack(spacing: 20) {
            // Encabezado con el ícono del otro usuario
            PeerHeaderView(multipeerManager: multipeerManager, showDeviceConnection: $showDeviceConnection)
            
            if !showDeviceConnection {
                // Selección de rol
                RolePickerView(selectedRole: $selectedRole, multipeerManager: multipeerManager)
                
                // Mostrar contenido basado en el rol
                if selectedRole == "sender" {
                    // Mostrar campos y botón para el emisor
                    SenderFormView(
                        amount: $amount,
                        concept: $concept,
                        isSendingPayment: $isSendingPayment,
                        multipeerManager: multipeerManager,
                        authenticateAction: authenticateUser,
                        sendPaymentAction: sendPayment
                    )
                } else if selectedRole == "receiver" {
                    // Mostrar mensaje para el receptor
                    ReceiverMessageView(multipeerManager: multipeerManager)
                } else {
                    // Cuando no se ha seleccionado ningún rol
                    Text("Por favor, selecciona tu rol para continuar.")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
                
                PaymentProgressView(
                    multipeerManager: multipeerManager,
                    isSendingPayment: isSendingPayment,
                    isReceivingPayment: isReceivingPayment,
                    showPaymentSuccess: showPaymentSuccess
                )
                
                Spacer()
                
            }
        }
            
            .padding()
            .navigationTitle("Realizar Pago")
            .onAppear {
                multipeerManager.isInPaymentView = true
                multipeerManager.start()
            }
            .onDisappear {
                multipeerManager.isInPaymentView = false
                multipeerManager.stop()
            }
            .onReceive(multipeerManager.$receivedPaymentRequest) { paymentRequest in
                if multipeerManager.isReceiver, let _ = paymentRequest {

                    showReceivedRequest = true
                }
            }

                .sheet(isPresented: $showReceivedRequest) {
                    if let paymentRequest = multipeerManager.receivedPaymentRequest {
                        PaymentRequestView(paymentRequest: paymentRequest, onAccept: {
                            // Aceptar el pago
                            authenticateUser { success in
                                if success {
                                    
                                    multipeerManager.updateReceiverState(.paymentAccepted)
                                    multipeerManager.sendAcceptanceToSender()
                                    processReceivedPayment()
                                    showReceivedRequest = false
                                } else {
                                    // Manejar autenticación fallida
                                    alertMessage = "Autenticación fallida."
                                    showAlert = true
                                }
                            }
                        }, onReject: {
                            // Rechazar el pago
                            multipeerManager.sendRejectionToSender()
                            multipeerManager.receivedPaymentRequest = nil
                            multipeerManager.updateReceiverState(.idle)
                            showReceivedRequest = false
                            
                        })
                    } else {
                        
                        EmptyView()
                        
                    }
                }.sheet(isPresented: $showPaymentSuccess) {
                    PaymentSuccessView(tokensEarned: tokensEarned, isReceiver: multipeerManager.isReceiver) {
                        // Acción para cerrar la hoja
                        showPaymentSuccess = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            .onChange(of: isSendingPayment) {  oldValue, newValue in
                if !newValue && paymentSent {
                    showConfirmation = true
                    resetForm()
                }
            }.onChange(of: multipeerManager.receiverState) { oldValue, newValue in
                if multipeerManager.isReceiver && newValue == .paymentCompleted {
                    // Aquí puedes llamar a un método específico para el receptor si es necesario
                    // Por ahora, ya estamos manejando el éxito en `processReceivedPayment()`
                }
            }.onChange(of: multipeerManager.senderState) { oldValue, newValue in
                if !multipeerManager.isReceiver && newValue == .paymentCompleted  {
                    processPaymentCompletionForSender()  // Manejar la finalización del pago para el emisor

                    // Cerrar la pantalla automáticamente después de 3 segundos
                }
                if !multipeerManager.isReceiver && newValue == .paymentRejected {

                        showRejectionAlert = true
                    isSendingPayment = false  // Restablecer el estado de envío
                }
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Pago Exitoso"),
                    message: Text("La transacción se ha completado con éxito."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
                .sheet(isPresented: $showRejectionAlert) {
                    PaymentRejectedView {
                        // Acción al cerrar la modal
                        showRejectionAlert = false
                        resetForm()
                        multipeerManager.updateSenderState(.idle)
                    }
                    // Configurar la altura de la modal para que ocupe el 33% de la pantalla
                    .presentationDetents([.fraction(0.33)])
                    .presentationDragIndicator(.visible)
                }.sheet(isPresented: $showDeviceConnection, onDismiss: {
                    // Acciones al cerrar la modal, si es necesario
                }) {
                    
                    DeviceConnectionView(multipeerManager: multipeerManager) {
                        // Acción al cerrar la modal desde DeviceConnectionView
                        showDeviceConnection = false
                    }
                    // Opcional: Configurar la altura de la modal si lo deseas
                    .presentationDetents([.fraction(0.5)])
                    .presentationDragIndicator(.visible)
                }
        
    }

    
}
