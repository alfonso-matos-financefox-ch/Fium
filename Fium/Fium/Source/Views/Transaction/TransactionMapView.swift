//
//  TransactionMapView.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 4/10/24.
//
import SwiftUI
import MapKit

struct TransactionMapView: View {
    let location: CLLocation

    @State private var region: MKCoordinateRegion

    init(location: CLLocation) {
        self.location = location
        _region = State(initialValue: MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [location]) { location in
            MapMarker(coordinate: location.coordinate, tint: .blue)
        }
        .navigationTitle("Ubicación de la transacción")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension CLLocation: Identifiable {
    public var id: Double {
        return self.coordinate.latitude + self.coordinate.longitude
    }
}

