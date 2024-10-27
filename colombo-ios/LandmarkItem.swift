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
    let id = UUID()
    let mapItem: MKMapItem
}