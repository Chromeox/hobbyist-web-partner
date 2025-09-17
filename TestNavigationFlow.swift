import SwiftUI

@main
struct TestNavigationApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationTestView()
        }
    }
}

struct NavigationTestView: View {
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            TestHomeView()
        } else {
            TestLoginNavigationView(onLoginSuccess: {
                isLoggedIn = true
            })
        }
    }
}

struct TestLoginNavigationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    let onLoginSuccess: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                Text("🎉 LOGIN → HOME NAVIGATION TEST 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.green)

                Text("Testing navigation from login to home screen")
                    .font(.subheadline)
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
            Button("🚀 TEST NAVIGATION 🚀") {
                isLoading = true
                // Simulate login process, then navigate to home
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isLoading = false
                    withAnimation(.easeInOut(duration: 0.5)) {
                        onLoginSuccess()
                    }
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
                ProgressView("Navigating to home...")
                    .padding()
            }

            VStack(spacing: 8) {
                Text("✅ Phase 1: LOGIN SCREEN WORKS")
                    .font(.caption)
                    .foregroundColor(.green)

                Text("⏳ Phase 2: Testing LOGIN → HOME navigation")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("📱 Enter email + password and tap button")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct TestHomeView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Success message
                    VStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("🎉 NAVIGATION SUCCESS! 🎉")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text("Login → Home flow working!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("✅ Phase 2 COMPLETE")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Search section
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search hobby classes...", text: $searchText)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Mock featured classes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Classes")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(mockClasses, id: \.id) { mockClass in
                                    TestClassCardView(title: mockClass.title, instructor: mockClass.instructor, price: mockClass.price)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("🎯 READY FOR PHASE 3: Feature Development")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)

                        Text("✅ Foundation proven working")
                        Text("✅ Navigation flow confirmed")
                        Text("✅ UI screens displaying correctly")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover Hobbies")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var mockClasses: [TestMockClass] {
        [
            TestMockClass(id: 1, title: "Pottery Basics", instructor: "Sarah Chen", price: "$45"),
            TestMockClass(id: 2, title: "Yoga Flow", instructor: "Emma Wilson", price: "$25"),
            TestMockClass(id: 3, title: "Cooking Italian", instructor: "Marco Rossi", price: "$65")
        ]
    }
}

struct TestMockClass {
    let id: Int
    let title: String
    let instructor: String
    let price: String
}

struct TestClassCardView: View {
    let title: String
    let instructor: String
    let price: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 80)
                .cornerRadius(8)

            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text("with \(instructor)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(price)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .frame(width: 140)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    NavigationTestView()
}