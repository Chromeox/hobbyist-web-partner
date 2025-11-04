import SwiftUI

struct LicensesView: View {
    let licenses = [
        License(
            name: "Supabase Swift",
            url: "https://github.com/supabase/supabase-swift",
            license: "MIT License",
            description: "Swift client for Supabase"
        ),
        License(
            name: "Stripe iOS SDK",
            url: "https://github.com/stripe/stripe-ios",
            license: "MIT License",
            description: "Stripe iOS SDK for payment processing"
        ),
        License(
            name: "Kingfisher",
            url: "https://github.com/onevcat/Kingfisher",
            license: "MIT License",
            description: "A lightweight, pure-Swift library for downloading and caching images"
        ),
        License(
            name: "SwiftUI",
            url: "https://developer.apple.com/xcode/swiftui/",
            license: "Apple Developer Agreement",
            description: "Apple's declarative UI framework"
        )
    ]
    
    var body: some View {
        List {
            Section {
                Text("This app uses the following open source libraries and frameworks. We are grateful to the developers who make these tools available.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            ForEach(licenses, id: \.name) { license in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(license.name)
                            .font(.headline)
                            .fontWeight(.medium)
                        Spacer()
                        Link("View", destination: URL(string: license.url)!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text(license.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(license.license)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MIT License")
                        .font(.headline)
                    
                    Text("""
                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                    
                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                    
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                    """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Common Licenses")
            }
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct License {
    let name: String
    let url: String
    let license: String
    let description: String
}

struct LicensesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LicensesView()
        }
    }
}