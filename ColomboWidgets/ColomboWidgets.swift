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
    }
}

struct LandmarkActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LandmarkActivityAttributes.self) { context in
            // Live Activity View
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
                
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image("DynamicIslandIcon")
                            .frame(width: 24, height: 24)
                            .padding(4)
                        Text(context.state.landmarkName)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary) // Ensure text is visible
                    }
                    .onAppear {
                        print("DEBUG: Landmark name: \(context.state.landmarkName)")
                    }
                    
                    Text(String(format: "%.0f meters away", context.state.distance))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .activityBackgroundTint(Color.white.opacity(0.8))
            .activitySystemActionForegroundColor(.blue)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image("DynamicIslandIcon")
                        .frame(width: 24, height: 24)
                        .padding(4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.0f m", context.state.distance))
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.landmarkName)
                        .font(.headline)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image("DynamicIslandIcon").frame(width: 24, height: 24)
                    .padding(4)
            } compactTrailing: {
                Text(String(format: "%.0f m", context.state.distance))
                    .font(.callout)
                    .monospacedDigit()
            } minimal: {
                Image("DynamicIslandIcon").frame(width: 24, height: 24)
                    .padding(4)
            }
        }
    }
}

#Preview("Live Activity", as: .content, using: LandmarkActivityAttributes(initialLandmarkName: "Test Landmark")) {
    LandmarkActivityWidget()
} contentStates: {
    LandmarkActivityAttributes.ContentState(landmarkName: "Eiffel Tower", distance: 100.0)
    LandmarkActivityAttributes.ContentState(landmarkName: "Eiffel Tower", distance: 50.0)
}
