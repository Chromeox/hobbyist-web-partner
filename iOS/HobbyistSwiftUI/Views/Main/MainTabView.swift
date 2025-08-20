import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
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

struct HomeView: View {
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
                                    ClassCard()
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

struct ClassCard: View {
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

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    let categories = ["Fitness", "Arts", "Music", "Cooking", "Dance", "Technology", "Language", "Photography"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search classes...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Featured Classes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Classes")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(0..<5) { _ in
                            ClassListItem()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ClassListItem: View {
    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Guitar Lessons for Beginners")
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Learn the basics of guitar playing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("4.9", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("$45/session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "heart")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct BookingsView: View {
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedSegment) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedSegment == 0 {
                    // Upcoming bookings
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<2) { _ in
                                BookingCard(isPast: false)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Past bookings
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<5) { _ in
                                BookingCard(isPast: true)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("My Bookings")
        }
    }
}

struct BookingCard: View {
    let isPast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pottery Making Workshop")
                        .font(.headline)
                    
                    Text(isPast ? "Completed on Dec 15, 2024" : "Tomorrow at 2:00 PM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPast {
                    Button("Rate") {
                        // Rate action
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                } else {
                    Text("Confirmed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack {
                Label("Central Studio", systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !isPast {
                    Button("View Details") {
                        // View details action
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.fullName ?? "User")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account Settings
                Section("Account") {
                    NavigationLink(destination: Text("Edit Profile")) {
                        Label("Edit Profile", systemImage: "person.fill")
                    }
                    
                    NavigationLink(destination: Text("Payment Methods")) {
                        Label("Payment Methods", systemImage: "creditcard.fill")
                    }
                    
                    NavigationLink(destination: Text("Credits")) {
                        Label("My Credits", systemImage: "dollarsign.circle.fill")
                    }
                }
                
                // Preferences
                Section("Preferences") {
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy", systemImage: "lock.fill")
                    }
                }
                
                // Support
                Section("Support") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("Contact Us")) {
                        Label("Contact Us", systemImage: "envelope.fill")
                    }
                }
                
                // Sign Out
                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func signOut() {
        Task {
            await authManager.signOut()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthenticationManager.shared)
    }
}