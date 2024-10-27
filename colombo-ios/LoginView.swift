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
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
            ZStack {
                Color(red: 252/255, green: 248/255, blue: 245/255)
                    .ignoresSafeArea()
                
                VStack {
                    Image("BigLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 350.0, height: 100.0)
                        .scaledToFit()
                        .padding(.bottom, 100.0)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .submitLabel(.next) // Shows "next" on keyboard
                        .onSubmit {
                            // Move focus to password field
                            // Note: This requires iOS 15+
                        }
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .submitLabel(.go) // Shows "go" on keyboard
                        .onSubmit {
                            // Execute login when return is pressed on password field
                            signIn()
                        }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        signIn()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Log In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isLoading)
                    .padding()
                }
                .padding()
            }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                
                // Update UI on the main thread
                await MainActor.run {
                    isLoading = false
                    isLoggedIn = true
                }
            } catch {
                // Handle error on the main thread
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(true))
}
