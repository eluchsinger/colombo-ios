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
    let userLocation: CLLocation?  // Add this property

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

            if let userLocation = userLocation,
               let landmarkLocation = landmark.mapItem.placemark.location {
                Text(String(format: "%.0f meters away", landmarkLocation.distance(from: userLocation)))
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
