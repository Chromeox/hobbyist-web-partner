import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                Text("Hobbyist Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)

            // Form Fields
            VStack(spacing: 16) {
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

            // Login Button
            Button("Login") {
                isLoading = true
                // Basic action for now - just toggle loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background((!email.isEmpty && !password.isEmpty) ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.horizontal)

            if isLoading {
                ProgressView("Signing in...")
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}