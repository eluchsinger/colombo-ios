//
//  PrimaryLandmarkView.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 28.10.2024.
//

import MapKit
import SwiftUI

struct PrimaryLandmarkView: View {
    let landmark: LandmarkItem

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(landmark.mapItem.name ?? "Unknown Landmark")
                        .font(.title2)
                        .bold()

                    if let subtitle = formatAddress(
                        from: landmark.mapItem.placemark)
                    {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }

            if let distance = landmark.mapItem.placemark.location?.distance(
                from: CLLocation(
                    latitude: landmark.mapItem.placemark.coordinate.latitude,
                    longitude: landmark.mapItem.placemark.coordinate.longitude
                ))
            {
                Text(String(format: "%.0f meters away", distance))
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    private func formatAddress(from placemark: MKPlacemark) -> String? {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
        ].compactMap { $0 }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
