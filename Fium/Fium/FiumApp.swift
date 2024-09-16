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

    init() {
        // Configura Firebase
        FirebaseApp.configure()
        // Solicita permisos de notificaciones
        requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            LoginView()
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

