import SwiftUI

/// Landing page view for new users
/// Inspired by modern language learning app designs
/// Uses assets from Assets.xcassets/LandingPage/
struct LandingPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogin = false
    @State private var showSignup = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("LandingGradientStart"),
                    Color("LandingGradientEnd")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Progress bar
                ProgressView(value: 1.0)
                    .tint(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
                
                // Hero section with illustration
                ZStack {
                    // Hero illustration
                    // Note: Download image from URL in LANDING_PAGE_ASSETS.md
                    // and place in Assets.xcassets/LandingPage/HeroIllustration.imageset/
                    Image("HeroIllustration")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 350)
                        .padding(.horizontal, 20)
                    
                    // Speech bubbles overlay
                    VStack {
                        HStack(alignment: .top) {
                            // Left speech bubble
                            Text("Let's create!")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.black)
                                )
                                .foregroundColor(.white)
                                .offset(x: 20, y: 40)
                            
                            Spacer()
                            
                            // Right speech bubble
                            Text("Let's go!")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.black)
                                )
                                .foregroundColor(.white)
                                .offset(x: -20, y: 40)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
                .frame(height: 400)
                
                Spacer()
                
                // Content card
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Start Creating Now 🚀")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("Discover Vancouver's most creative hobby classes today! 🎨")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Button(action: { showLogin = true }) {
                                Text("Log In")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                            
                            Button(action: { showSignup = true }) {
                                Text("Sign Up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        
                        Button(action: { 
                            // Handle guest continuation
                            print("Continue as guest")
                        }) {
                            Text("Continue as Guest")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.black, lineWidth: 2)
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(30)
                .background(.white)
                .cornerRadius(30, corners: [.topLeft, .topRight])
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(onLoginSuccess: { _ in })
        }
        .sheet(isPresented: $showSignup) {
            // Add signup view here
            Text("Sign Up View")
        }
    }
}

// Helper extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    LandingPageView()
}