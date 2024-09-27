//
//  UserIconView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 27/9/24.
//
import SwiftUI

struct UserIconView: View {
    let iconName: String
    let isConnected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)

            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)
                .offset(x: 5, y: -5)
        }
    }
}

