//
//  LandmarkItem.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//


import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct LandmarkItem: Identifiable {
    let id: String
    let mapItem: MKMapItem
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        self.id = mapItem.identifier?.rawValue ?? ""  // Using MKMapItem's identifier as the id
    }
}
