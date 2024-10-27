import SwiftUI
import MapKit

struct MonumentView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            Button("Log out") {
                isLoggedIn = false // Log out
            }
            .padding()
            
            if let location = locationManager.location {
                Text("Current Location: \(location.latitude), \(location.longitude)")
                    .padding()
            } else if let error = locationManager.locationError {
                Text("Location error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Fetching location...")
                    .padding()
            }
            
            Divider()
            
            Text("Nearby Points of Interest:")
                .font(.headline)
                .padding(.top)
            
            List(locationManager.pointsOfInterest, id: \.placemark) { item in
                VStack(alignment: .leading) {
                    Text(item.name ?? "Unknown")
                        .font(.subheadline)
                        .bold()
                    Text(item.placemark.title ?? "No address available")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}
