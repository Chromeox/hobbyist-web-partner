import SwiftUI

struct ProductionLoginView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var fullName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Hobbyist")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Discover your next passion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal)

                // Action Button
                Button(isSignUp ? "Create Account" : "Sign In") {
                    Task {
                        if isSignUp {
                            await supabaseService.signUp(
                                email: email,
                                password: password,
                                fullName: fullName
                            )
                        } else {
                            await supabaseService.signIn(
                                email: email,
                                password: password
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(formIsValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(supabaseService.isLoading || !formIsValid)
                .padding(.horizontal)

                // Toggle
                Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                    isSignUp.toggle()
                    fullName = ""
                }
                .foregroundColor(.blue)

                if supabaseService.isLoading {
                    ProgressView(isSignUp ? "Creating account..." : "Signing in...")
                        .padding()
                }

                Spacer()
            }
            .padding()
        }
    }

    private var formIsValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
}

#Preview {
    ProductionLoginView()
        .environmentObject(SimpleSupabaseService.shared)
}