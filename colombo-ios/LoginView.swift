//
//  ContentView.swift
//  colombo.ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = "eluchsingerm@hotmail.com"
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email
        case password
    }
    
    var body: some View {
        ZStack {
            VStack {
                Image("BigLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 350.0, height: 100.0)
                    .scaledToFit()
                    .padding(.bottom, 100.0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    TextField("Enter your email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                        .contentShape(Rectangle())
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    SecureField("Enter your password", text: $password)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                        .contentShape(Rectangle())
                        .submitLabel(.go)
                        .onSubmit {
                            signIn()
                        }
                }
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    signIn()
                }, label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                    }
                })
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
                .disabled(isLoading)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
