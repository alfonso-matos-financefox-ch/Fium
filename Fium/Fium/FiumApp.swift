//
//  FiumApp.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 13/9/24.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct FiumApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    var bonjourService: BonjourService?
//    @StateObject private var bluetoothManager = BluetoothManager() // Instancia de BluetoothManager
    
    init() {
        // Configura Firebase
        FirebaseApp.configure()
        // Solicita permisos de notificaciones
        requestNotificationPermissions()
        // Iniciar BonjourService
//        bonjourService = BonjourService()
//        bonjourService?.publishService()
    }

    var body: some Scene {
        WindowGroup {
            LoginView()
//            .environmentObject(bluetoothManager)
        }
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permisos de notificación otorgados.")
            } else {
                print("Permisos de notificación denegados.")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Configuraciones adicionales si es necesario
}

