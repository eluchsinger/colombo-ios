//
//  Monument.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//
import SwiftUI

struct MonumentView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        VStack
        {
            Button("Log out"){
                isLoggedIn = false
            }
            Text("You're at the Eiffel Tower")
        }
    }
    
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}
