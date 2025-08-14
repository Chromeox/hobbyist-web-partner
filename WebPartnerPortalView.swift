import SwiftUI
import WebKit

struct WebPartnerPortalView: View {
    var body: some View {
        NavigationView {
            WebView(url: URL(string: "http://localhost:3000")!)
                .navigationTitle("Partner Portal")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update if needed
    }
}

#Preview {
    WebPartnerPortalView()
}