import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo and Welcome
                VStack(spacing: 16) {
                    Image(systemName: "figure.walk.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)
                    
                    Text("Welcome to Hobbyist")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Discover and book amazing hobby classes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
                
                // Tab Selection
                Picker("", selection: $selectedTab) {
                    Text("Sign In").tag(0)
                    Text("Sign Up").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    SignInView()
                        .tag(0)
                    
                    SignUpView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Spacer()
                
                // Social Sign In
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal)
                    
                    Text("Or continue with")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await AuthenticationManager.shared.signInWithApple(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error)")
        }
    }
}

extension AuthenticationManager {
    @MainActor
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        authError = nil
        
        do {
            _ = try await authService.signInWithApple(credential: credential)
        } catch let error as AuthError {
            authError = error
        } catch {
            authError = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
}