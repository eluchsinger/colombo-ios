//
//  ColomboWidgets.swift
//  ColomboWidgets
//
//  Created by Esteban Luchsinger on 10.11.2024.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct ColomboWidgetBundle: WidgetBundle {
    var body: some Widget {
        LandmarkActivityWidget()
        ColomboWidgetsLiveActivity()
    }
}

struct LandmarkActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LandmarkActivityAttributes.self) { context in
            // Live Activity View
            VStack {
                HStack {
                    Image(systemName: "building.columns.fill")
                    Text(context.state.landmarkName)
                        .font(.headline)
                }
                Text(String(format: "%.0f meters away", context.state.distance))
                    .font(.subheadline)
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island View
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "building.columns.fill")
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.0f m", context.state.distance))
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.landmarkName)
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: "building.columns.fill")
            } compactTrailing: {
                Text(String(format: "%.0f m", context.state.distance))
            } minimal: {
                Image(systemName: "building.columns.fill")
            }
        }
    }
}
