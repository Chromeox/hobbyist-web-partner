#!/bin/bash

# Deploy Legal Pages Script for HobbyistSwiftUI
# This script helps you quickly deploy your Terms of Service and Privacy Policy

echo "🚀 Hobbyist Legal Pages Deployment"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -d "web-partner" ]; then
    echo "❌ Error: web-partner directory not found"
    echo "Please run this script from the HobbyistSwiftUI root directory"
    exit 1
fi

cd web-partner

# Option 1: Deploy to Vercel (Recommended)
deploy_to_vercel() {
    echo "📦 Deploying to Vercel..."
    
    # Check if Vercel CLI is installed
    if ! command -v vercel &> /dev/null; then
        echo "Installing Vercel CLI..."
        npm install -g vercel
    fi
    
    # Deploy
    vercel --prod
    
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "Your legal pages are now available at:"
    echo "  Privacy Policy: https://your-domain.vercel.app/legal/privacy"
    echo "  Terms of Service: https://your-domain.vercel.app/legal/terms"
}

# Option 2: Build for static hosting
build_static() {
    echo "🏗️ Building static files..."
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi
    
    # Build the app
    npm run build
    
    echo ""
    echo "✅ Build complete!"
    echo ""
    echo "Static files are ready in the '.next' directory"
    echo "You can now upload them to any static hosting service"
}

# Option 3: Run locally for testing
run_local() {
    echo "🖥️ Starting local development server..."
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi
    
    # Start dev server
    npm run dev &
    
    echo ""
    echo "✅ Local server started!"
    echo ""
    echo "Your legal pages are available at:"
    echo "  Privacy Policy: http://localhost:3000/legal/privacy"
    echo "  Terms of Service: http://localhost:3000/legal/terms"
    echo ""
    echo "Press Ctrl+C to stop the server"
    
    wait
}

# Option 4: Deploy to GitHub Pages
deploy_github_pages() {
    echo "📄 Creating standalone HTML files for GitHub Pages..."
    
    # Create a simple directory for GitHub Pages
    mkdir -p ../github-pages-legal
    
    # Create standalone Privacy Policy HTML
    cat > ../github-pages-legal/privacy.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Hobbyist</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #2563eb; }
        h2 { color: #1e40af; margin-top: 30px; }
        ul { padding-left: 20px; }
        .date { color: #666; font-style: italic; }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p class="date">Last updated: <script>document.write(new Date().toLocaleDateString())</script></p>
    
    <h2>1. Information We Collect</h2>
    <p>We collect information you provide directly to us, including name, email, profile information from social logins, payment information via Stripe, and booking preferences.</p>
    
    <h2>2. How We Use Your Information</h2>
    <p>We use your information to manage your account, process bookings, send confirmations, improve our services, and comply with legal obligations.</p>
    
    <h2>3. Data Security</h2>
    <p>We implement appropriate measures to protect your personal information against unauthorized access or disclosure.</p>
    
    <h2>4. Your Rights</h2>
    <p>You have the right to access, correct, delete your information, opt-out of marketing, and export your data.</p>
    
    <h2>5. Contact Us</h2>
    <p>Email: privacy@hobbyist.app</p>
</body>
</html>
EOF

    # Create standalone Terms of Service HTML
    cat > ../github-pages-legal/terms.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service - Hobbyist</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #2563eb; }
        h2 { color: #1e40af; margin-top: 30px; }
        ul { padding-left: 20px; }
        .date { color: #666; font-style: italic; }
    </style>
</head>
<body>
    <h1>Terms of Service</h1>
    <p class="date">Last updated: <script>document.write(new Date().toLocaleDateString())</script></p>
    
    <h2>1. Acceptance of Terms</h2>
    <p>By using Hobbyist, you agree to be bound by these Terms of Service.</p>
    
    <h2>2. Description of Service</h2>
    <p>Hobbyist connects users with hobby classes and studios, facilitating bookings and payments.</p>
    
    <h2>3. User Accounts</h2>
    <p>You must provide accurate information and maintain account security.</p>
    
    <h2>4. Bookings and Payments</h2>
    <p>Bookings create contracts with studios. Payments are processed through Stripe. Cancellation policies vary by studio.</p>
    
    <h2>5. User Conduct</h2>
    <p>Users must comply with laws, respect others, and use the service appropriately.</p>
    
    <h2>6. Contact Information</h2>
    <p>Email: legal@hobbyist.app</p>
</body>
</html>
EOF

    echo ""
    echo "✅ GitHub Pages files created!"
    echo ""
    echo "To deploy to GitHub Pages:"
    echo "1. Create a new GitHub repository called 'hobbyist-legal'"
    echo "2. Push the files from 'github-pages-legal' directory"
    echo "3. Enable GitHub Pages in repository settings"
    echo "4. Your URLs will be:"
    echo "   https://[your-username].github.io/hobbyist-legal/privacy.html"
    echo "   https://[your-username].github.io/hobbyist-legal/terms.html"
}

# Show menu
echo "Choose deployment option:"
echo "1) Deploy to Vercel (Recommended)"
echo "2) Build static files"
echo "3) Run locally for testing"
echo "4) Create GitHub Pages files"
echo "5) Exit"
echo ""
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        deploy_to_vercel
        ;;
    2)
        build_static
        ;;
    3)
        run_local
        ;;
    4)
        deploy_github_pages
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "🎉 Done! Your legal pages are ready to use."
echo ""
echo "Next steps:"
echo "1. Update the URLs in your Facebook App settings"
echo "2. Update the URLs in your iOS app if needed"
echo "3. Update any references in your Supabase configuration"