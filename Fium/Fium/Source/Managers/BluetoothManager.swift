//
//  BluetoothManager.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 16/9/24.
//

import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var isBluetoothOn: Bool = false
    var centralManager: CBCentralManager?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Método que se llama cuando el estado de Bluetooth cambia
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth está encendido y listo.")
            isBluetoothOn = true
        case .poweredOff:
            print("Bluetooth está apagado.")
            isBluetoothOn = false
        case .resetting:
            print("Bluetooth está reiniciando.")
            isBluetoothOn = false
        case .unauthorized:
            print("El acceso a Bluetooth no está autorizado.")
            isBluetoothOn = false
        case .unsupported:
            print("El dispositivo no soporta Bluetooth.")
            isBluetoothOn = false
        case .unknown:
            print("El estado de Bluetooth es desconocido.")
            isBluetoothOn = false
        @unknown default:
            print("Estado de Bluetooth no conocido.")
            isBluetoothOn = false
        }
    }
}
