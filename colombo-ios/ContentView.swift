//
//  ContentView.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//
import SwiftUI


struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            MonumentView(isLoggedIn: $isLoggedIn)
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

#Preview {
    ContentView()
}
