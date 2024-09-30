//
//  RolePickerView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//
import SwiftUI

struct RolePickerView: View {
    @Binding var selectedRole: String
    @ObservedObject var multipeerManager: MultipeerManager

    var body: some View {
        Picker("Selecciona tu rol", selection: $selectedRole) {
            Text("Selecciona un rol").tag("none")
            Text("Emisor").tag("sender")
            Text("Receptor").tag("receiver")
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: selectedRole) { oldValue, newValue in
            if newValue != "none" {
                multipeerManager.selectedRole = newValue
                multipeerManager.sendRole(newValue)
                if newValue == "receiver" {
                    multipeerManager.isReceiver = true
                    multipeerManager.updateReceiverState(.roleSelectedReceiver)
                } else if newValue == "sender" {
                    multipeerManager.isReceiver = false
                    multipeerManager.updateSenderState(.roleSelectedSender)
                }
            }
        }
        .onReceive(multipeerManager.$selectedRole) { newRole in
            selectedRole = newRole
        }
    }
}

