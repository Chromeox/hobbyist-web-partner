import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Group {
                    termsSection(
                        title: "Acceptance of Terms",
                        content: """
                        By accessing and using the Hobbyist app, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.
                        """
                    )
                    
                    termsSection(
                        title: "Use License",
                        content: """
                        Permission is granted to temporarily download one copy of Hobbyist for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
                        
                        • Modify or copy the materials
                        • Use the materials for commercial purposes
                        • Attempt to reverse engineer any software
                        • Remove any copyright or proprietary notations
                        """
                    )
                    
                    termsSection(
                        title: "User Account",
                        content: """
                        When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities under your account.
                        
                        You agree not to disclose your password to any third party and to take sole responsibility for activities under your account.
                        """
                    )
                    
                    termsSection(
                        title: "Bookings and Payments",
                        content: """
                        • All bookings are subject to availability
                        • Payment is required at the time of booking
                        • Cancellation policies vary by studio
                        • Refunds are processed according to studio policies
                        • You are responsible for attending booked classes
                        """
                    )
                    
                    termsSection(
                        title: "Prohibited Uses",
                        content: """
                        You may not use our service:
                        
                        • For any unlawful purpose
                        • To solicit others to perform unlawful acts
                        • To violate any international, federal, provincial or state regulations, rules, laws, or local ordinances
                        • To infringe upon or violate our intellectual property rights or the intellectual property rights of others
                        • To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate
                        • To submit false or misleading information
                        """
                    )
                    
                    termsSection(
                        title: "Disclaimers",
                        content: """
                        The information on this app is provided on an 'as is' basis. To the fullest extent permitted by law, we exclude all representations, warranties, and conditions relating to our app and the use of this app.
                        
                        We make no guarantees regarding the availability of classes or the quality of services provided by partner studios.
                        """
                    )
                    
                    termsSection(
                        title: "Limitation of Liability",
                        content: """
                        In no event shall Hobbyist or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Hobbyist's app.
                        """
                    )
                    
                    termsSection(
                        title: "Governing Law",
                        content: """
                        These terms and conditions are governed by and construed in accordance with the laws of British Columbia, Canada, and you irrevocably submit to the exclusive jurisdiction of the courts in that state or location.
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
    
    private func termsSection(title: String, content: String) -> some View {
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

struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TermsOfServiceView()
        }
    }
}