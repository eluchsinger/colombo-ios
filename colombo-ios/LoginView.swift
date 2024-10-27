//
//  ContentView.swift
//  colombo.ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            
            Color(red: 252 / 255, green: 248 / 255, blue: 245 / 255)
                .ignoresSafeArea() // Extend color to cover the safe area
            
            VStack {
                Image("BigLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 350.0, height: 100.0)
                    .scaledToFit()
                    .padding(.bottom, 100.0) // Adds space below the logo
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                
                Button(action: {
                    // Add login action here
                    print("Logging in with email: \(email), password: \(password)")
                    isLoggedIn = true;
                }) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .padding()
        }
    }
    
}

#Preview {
    LoginView(isLoggedIn: .constant(true))
}
