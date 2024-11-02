import SwiftUI
import Supabase

// Define AuthState class
class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool = false
}

struct UserSettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemNotifications") private var useSystemNotifications = true
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @State private var showingLogoutAlert = false
    @State private var username: String = ""
    @EnvironmentObject var authState: AuthState
    @Environment(\.colorScheme) var colorScheme
    
    private var effectiveDarkMode: Bool {
        useSystemAppearance ? colorScheme == .dark : isDarkMode
    }
    
    func toggleAppearance() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = useSystemAppearance ? .unspecified : (isDarkMode ? .dark : .light)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(username)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Use System Settings", isOn: $useSystemAppearance)
                        .onChange(of: useSystemAppearance) { _ in
                            toggleAppearance()
                        }
                    
                    if !useSystemAppearance {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .onChange(of: isDarkMode) { _ in
                                toggleAppearance()
                            }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $useSystemNotifications)
                }
                
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                Task {
                    if let email = try? await supabase.auth.session.user.email {
                        username = email
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await supabase.auth.signOut()
                        authState.isAuthenticated = false
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
            .environmentObject(AuthState())
    }
}
