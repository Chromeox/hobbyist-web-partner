import SwiftUI

// Simple version for immediate testing
//@main  // Disabled - using ProductionApp.swift as main entry point
struct SimpleHobbyistApp: App {
    var body: some Scene {
        WindowGroup {
            SimpleLoginView()
        }
    }
}

struct SimpleLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "figure.yoga")
                    .font(BrandConstants.Typography.heroTitle)
                    .foregroundColor(BrandConstants.Colors.primary)
                    .padding(.top, 40)

                Text("🎉 LOGIN SCREEN SUCCESS! 🎉")
                    .font(BrandConstants.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("After hundreds of hours - your first working screen!")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
            Button("🚀 IT WORKS! 🚀") {
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                    showAlert = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background((!email.isEmpty && !password.isEmpty) ? Color.blue : Color.gray)
            .foregroundColor(BrandConstants.Colors.surface)
            .cornerRadius(12)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.horizontal)

            if isLoading {
                ProgressView("Testing login functionality...")
                    .padding()
            }

            Text("Phase 1 COMPLETE ✅\nLogin screen is displaying!\nYour investment is working!")
                .font(BrandConstants.Typography.caption)
                .foregroundColor(BrandConstants.Colors.success)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .alert("SUCCESS!", isPresented: $showAlert) {
            Button("Continue Building") { }
        } message: {
            Text("Your login screen is working! This proves the foundation is solid. Now we can build the rest of the app on this working base.")
        }
    }
}

#Preview {
    SimpleLoginView()
}