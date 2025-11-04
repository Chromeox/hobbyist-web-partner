import SwiftUI

struct AcknowledgmentsView: View {
    let acknowledgments = [
        Acknowledgment(
            category: "Vancouver Creative Community",
            items: [
                "East Van Studios for inspiring our vision",
                "Local pottery studios for early feedback",
                "Vancouver makers and artists",
                "Community centers across the Lower Mainland"
            ]
        ),
        Acknowledgment(
            category: "Development & Design",
            items: [
                "Claude AI for development assistance",
                "SF Symbols for iconography",
                "Apple Developer community",
                "SwiftUI Beta testers and feedback"
            ]
        ),
        Acknowledgment(
            category: "Open Source Community",
            items: [
                "Supabase team for amazing backend tools",
                "Stripe for seamless payment processing",
                "Kingfisher contributors for image handling",
                "GitHub for code hosting and collaboration"
            ]
        ),
        Acknowledgment(
            category: "Beta Testers",
            items: [
                "Early adopters who tested the app",
                "Studio partners who provided feedback",
                "Friends and family for patience and support",
                "Vancouver tech community for encouragement"
            ]
        ),
        Acknowledgment(
            category: "Inspiration",
            items: [
                "ClassPass for proving the market",
                "Mindbody for studio management insights",
                "Local booking platforms for UX learnings",
                "Every hobbyist pursuing their passion"
            ]
        )
    ]
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Thank You!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Hobbyist wouldn't exist without the incredible support, feedback, and inspiration from our community. This app is built for hobbyists, by hobbyists.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            ForEach(acknowledgments, id: \.category) { acknowledgment in
                Section(acknowledgment.category) {
                    ForEach(acknowledgment.items, id: \.self) { item in
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(item)
                                .font(.body)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            Section {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Made with ❤️ in Vancouver")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Connecting people with their passions, one class at a time.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        if let instagramURL = URL(string: "https://instagram.com/hobbyistapp") {
                            Link(destination: instagramURL) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let twitterURL = URL(string: "https://twitter.com/hobbyistapp") {
                            Link(destination: twitterURL) {
                                Image(systemName: "message.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let emailURL = URL(string: "mailto:hello@hobbyist.app") {
                            Link(destination: emailURL) {
                                Image(systemName: "envelope.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Acknowledgment {
    let category: String
    let items: [String]
}

struct AcknowledgmentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AcknowledgmentsView()
        }
    }
}