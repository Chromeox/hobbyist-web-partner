import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Group {
                    policySection(
                        title: "Information We Collect",
                        content: """
                        We collect information you provide directly to us, such as when you create an account, book classes, or contact us for support. This may include:
                        
                        • Name and contact information
                        • Profile photos and preferences
                        • Payment information (processed securely)
                        • Class booking history and reviews
                        """
                    )
                    
                    policySection(
                        title: "How We Use Your Information",
                        content: """
                        We use the information we collect to:
                        
                        • Provide and improve our services
                        • Process bookings and payments
                        • Send you class reminders and updates
                        • Personalize your experience
                        • Respond to your questions and provide support
                        """
                    )
                    
                    policySection(
                        title: "Information Sharing",
                        content: """
                        We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:
                        
                        • With studios for class bookings
                        • With payment processors for secure transactions
                        • When required by law or to protect our rights
                        • With your explicit consent
                        """
                    )
                    
                    policySection(
                        title: "Data Security",
                        content: """
                        We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes:
                        
                        • Encryption of sensitive data
                        • Secure server infrastructure
                        • Regular security audits
                        • Limited access to personal information
                        """
                    )
                    
                    policySection(
                        title: "Your Rights",
                        content: """
                        You have the right to:
                        
                        • Access your personal information
                        • Correct inaccurate information
                        • Delete your account and data
                        • Export your data
                        • Opt out of marketing communications
                        """
                    )
                    
                    policySection(
                        title: "Contact Us",
                        content: """
                        If you have any questions about this Privacy Policy, please contact us at:
                        
                        Email: privacy@hobbyist.app
                        Address: Vancouver, BC, Canada
                        """
                    )
                }
                
                Text("Last updated: November 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PrivacyPolicyView()
        }
    }
}