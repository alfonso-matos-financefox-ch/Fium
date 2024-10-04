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
    
    @Environment(\.modelContext) var context
    @Query private var users: [User]  // Obtenemos el usuario
    
    @Environment(\.presentationMode) var presentationMode
    @State var amount = ""
    @State var concept = ""
    @EnvironmentObject var multipeerManager: MultipeerManager
    @State var showConfirmation = false
    @State var showReceivedRequest = false
    @State var isSendingPayment = false
    @State var paymentRequestSent = false
    @State var showAlert = false
    @State var alertMessage = ""
    @State var tokensEarned = 0
    @State var showRejectionAlert = false
    
    @State var selectedRole: String = "none"  // Rol seleccionado por el usuario (emisor o receptor)
    @State var isWaitingForTransfer = false  // Controla si este dispositivo está esperando la transferencia
    @State var isReceivingPayment = false  // Nuevo estado para el receptor
    @State var showPaymentSuccess = false
    @State var showDeviceConnection = true  // Mostrar la modal al iniciar
    @State private var showProcessingSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Encabezado con el ícono del otro usuario
            PeerHeaderView(showDeviceConnection: $showDeviceConnection).environmentObject(multipeerManager)
            
            if !showDeviceConnection {
                // Selección de rol
                RolePickerView(selectedRole: $selectedRole, onRoleChange: resetForm)
                    .environmentObject(multipeerManager)
                
                // Mostrar contenido basado en el rol
                if selectedRole == "sender" {
                    // Mostrar campos y botón para el emisor
                    SenderFormView(
                        amount: $amount,
                        concept: $concept,
                        isSendingPayment: $isSendingPayment,
                        authenticateAction: authenticateUser,
                        sendPaymentAction: sendPayment
                    ).environmentObject(multipeerManager)
                } else if selectedRole == "receiver" {
                    // Mostrar mensaje para el receptor
                    ReceiverMessageView().environmentObject(multipeerManager)
                } else {
                    // Cuando no se ha seleccionado ningún rol
                    Text("Por favor, selecciona tu rol para continuar.")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
                
                PaymentProgressView(
                    isSendingPayment: isSendingPayment,
                    isReceivingPayment: isReceivingPayment,
                    showPaymentSuccess: showPaymentSuccess
                ).environmentObject(multipeerManager)
                
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
                                    processReceivedPayment() // TODO: ESTO NO SE DEBERÍA HACER AQUI
                                    showReceivedRequest = false
                                    print("Pago aceptado por el receptor - paymentView")
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
                            print("Pago rechazado por el receptor")
                            
                        }) .presentationDetents([.fraction(0.5)])
                    } else {
                        
                        EmptyView()
                        
                    }
                }.sheet(isPresented: $showPaymentSuccess) {
                    PaymentSuccessView(tokensEarned: tokensEarned, isReceiver: multipeerManager.isReceiver) {
                        // Acción para cerrar la hoja
                        showPaymentSuccess = false
                        presentationMode.wrappedValue.dismiss()
                    }.presentationDetents([.fraction(0.5)])
                }
                .sheet(isPresented: $showRejectionAlert) {
                    PaymentRejectedView {
                        // Acción al cerrar la modal
                        showRejectionAlert = false
                        resetForm()
                        print("show rejection alert")
                        multipeerManager.updateSenderState(.idle)
                    }
                    // Configurar la altura de la modal para que ocupe el 33% de la pantalla
                    .presentationDetents([.fraction(0.50)])
                    .presentationDragIndicator(.visible)
                }.sheet(isPresented: $showDeviceConnection, onDismiss: {
                    // Acciones al cerrar la modal, si es necesario
                }) {
                    
                    DeviceConnectionView() {
                        // Acción al cerrar la modal desde DeviceConnectionView
                        showDeviceConnection = false
                    }
                    // Opcional: Configurar la altura de la modal si lo deseas
                    .presentationDetents([.fraction(0.6)])
                    .presentationDragIndicator(.visible)
                    .environmentObject(multipeerManager)
                }.sheet(isPresented: $showProcessingSheet) {
                    ProcessingPaymentView(isProcessing: multipeerManager.senderState == .processingPayment,
                      onRetry: {
                          // Retry transaction logic
                          multipeerManager.handlePaymentAccepted(amount: Double(amount) ?? 0, concept: concept, emitterID: multipeerManager.currentUser?.id.uuidString ?? "", receiverID: multipeerManager.peerUser?.id.uuidString ?? "")
                      },
                      onCancel: {
                          // Cancel payment and reset
                          showProcessingSheet = false
                          multipeerManager.updateSenderState(.idle)
                      },
                      transactionFailed: multipeerManager.senderState == .paymentFailed)
                }
            .onChange(of: isSendingPayment) {  oldValue, newValue in
                if !newValue && paymentRequestSent {
                    showConfirmation = true
                    resetForm()
                }
            }.onChange(of: multipeerManager.receiverState) { oldValue, newValue in
                print("Entra en receiverState: \(newValue)")
                    
                if multipeerManager.isReceiver && newValue == .paymentAccepted {
                    // El receptor ha aceptado el pago y está esperando confirmación del emisor
                    isReceivingPayment = true
                }

                if multipeerManager.isReceiver && newValue == .paymentCompleted {
                    // El emisor ha confirmado que la transacción fue exitosa
                    // Aquí podrías calcular los tokens ganados por el receptor
                    tokensEarned = calculateTokens(for: multipeerManager.receivedPaymentRequest?.amount ?? 0)

                    showPaymentSuccess = true
                    isReceivingPayment = false
                }
                
                if multipeerManager.isReceiver && newValue == .paymentFailed {
                    // El emisor ha informado que la transacción ha fallado
                    showAlert = true
                    alertMessage = "La transacción ha fallado."
                    isReceivingPayment = false
                }
            }.onChange(of: multipeerManager.senderState) { oldValue, newValue in
                print("Entra en senderState, oldValue: \(oldValue), newValue: \(newValue)")
                if !multipeerManager.isReceiver && newValue == .paymentAccepted {
                    // Manejar el estado .paymentAccepted si es necesario
                    print("Pago aceptado por el receptor - PaymentAccepted")
                    // Mostrar la sheet indicando que estamos procesando el pago
                    showProcessingSheet = true
                    // El receptor ha aceptado el pago, ahora procesamos la transacción con el servicio de pago
                    multipeerManager.handlePaymentAccepted(amount: Double(amount) ?? 0, concept: concept, emitterID: multipeerManager.currentUser?.id.uuidString ?? "", receiverID: multipeerManager.peerUser?.id.uuidString ?? "")

                }
                if !multipeerManager.isReceiver && newValue == .paymentCompleted  {
                    showProcessingSheet = false
                    processPaymentCompletionForSender()  // Manejar la finalización del pago para el emisor
                    // Cerrar la sheet de procesamiento y mostrar la pantalla de éxito
                    
                    print("Procesando pago completado para el emisor")
                    // Cerrar la pantalla automáticamente después de 3 segundos
                }
                if !multipeerManager.isReceiver && newValue == .paymentFailed {
                    // La transacción falló, mostrar error
                    showAlert = true
                    alertMessage = "La transacción ha fallado."
                    // Mostrar que la transacción ha fallado y permitir un retry
                    showProcessingSheet = true
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
                
        
    }

    
}
