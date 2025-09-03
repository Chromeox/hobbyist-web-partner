import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            BookingsView()
                .tabItem {
                    Label("Bookings", systemImage: "calendar")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.accentColor)
    }
}

struct MainHomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text(authManager.currentUser?.fullName ?? "Hobbyist")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Stats Cards
                    HStack(spacing: 16) {
                        StatCard(
                            icon: "trophy.fill",
                            value: "12",
                            label: "Classes Completed",
                            color: .yellow
                        )
                        
                        StatCard(
                            icon: "star.fill",
                            value: "48",
                            label: "Points Earned",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Upcoming Classes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Classes")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<3) { _ in
                                    SimpleClassCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recommended for You
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended for You")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<5) { _ in
                                    RecommendationCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SimpleClassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.accentColor.opacity(0.6), .accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "figure.yoga")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Yoga")
                    .font(.headline)
                
                Text("Tomorrow at 9:00 AM")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("with Sarah Johnson")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 200)
    }
}

struct RecommendationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 140, height: 140)
                .overlay(
                    Image(systemName: "paintbrush.fill")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Watercolor Painting")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Text("4.8")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• $35")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 140)
    }
}







struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthenticationManager.shared)
    }
}