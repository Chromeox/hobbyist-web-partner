/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
  typescript: {
    // Type checking is handled by separate script
    ignoreBuildErrors: false,
  },
  eslint: {
    // ESLint checking during builds
    ignoreDuringBuilds: false,
  },
  images: {
    domains: ['localhost', 'images.unsplash.com'],
  },
  // Enable static export if needed for deployment
  // output: 'export',
  // trailingSlash: true,
}

module.exports = nextConfig