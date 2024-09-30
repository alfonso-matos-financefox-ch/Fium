//
//  PeerHeaderView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 29/9/24.
//
import SwiftUI

struct PeerHeaderView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @Binding var showDeviceConnection: Bool

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                showDeviceConnection = true
            }) {
                if let image = multipeerManager.peerImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        Circle()
                            .fill(multipeerManager.discoveredPeer != nil ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                            .offset(x: 5, y: -5)
                    }
                } else {
                    UserIconView(iconName: multipeerManager.peerIcon, isConnected: multipeerManager.discoveredPeer != nil)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding([.top, .trailing])
    }
}

