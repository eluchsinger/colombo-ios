//
//  ColomboWidgetsLiveActivity.swift
//  ColomboWidgets
//
//  Created by Esteban Luchsinger on 10.11.2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ColomboWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ColomboWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ColomboWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ColomboWidgetsAttributes {
    fileprivate static var preview: ColomboWidgetsAttributes {
        ColomboWidgetsAttributes(name: "World")
    }
}

extension ColomboWidgetsAttributes.ContentState {
    fileprivate static var smiley: ColomboWidgetsAttributes.ContentState {
        ColomboWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ColomboWidgetsAttributes.ContentState {
         ColomboWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ColomboWidgetsAttributes.preview) {
   ColomboWidgetsLiveActivity()
} contentStates: {
    ColomboWidgetsAttributes.ContentState.smiley
    ColomboWidgetsAttributes.ContentState.starEyes
}
