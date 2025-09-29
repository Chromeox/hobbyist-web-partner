/**
 * Optimized Next.js configuration for V8 runtime performance
 * 
 * Key optimizations:
 * 1. SWC minification for faster builds
 * 2. Module concatenation for better tree-shaking
 * 3. Optimized chunk splitting
 * 4. Image optimization settings
 * 5. Compiler optimizations for React
 */

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Use SWC for faster builds and better optimization
  swcMinify: true,
  
  // React compiler optimizations
  compiler: {
    // Remove console logs in production
    removeConsole: process.env.NODE_ENV === 'production' ? {
      exclude: ['error', 'warn']
    } : false,
    
    // Emotion CSS-in-JS optimizations (if using emotion)
    emotion: false,
    
    // Styled components optimizations (if using styled-components)
    styledComponents: false
  },
  
  // Enable React strict mode at the top level
  reactStrictMode: true,
  
  // Experimental features for better performance
  experimental: {
    // Optimize CSS loading
    optimizeCss: true,
    
    // Server components optimization
    serverComponentsExternalPackages: ['@supabase/supabase-js'],
    
    // Optimize package imports
    optimizePackageImports: [
      'lucide-react',
      'framer-motion',
      'chart.js',
      'react-chartjs-2'
    ]
  },
  
  // Webpack optimizations
  webpack: (config, { dev, isServer }) => {
    // Production optimizations
    if (!dev) {
      // Optimize chunk splitting
      config.optimization = {
        ...config.optimization,
        moduleIds: 'deterministic',
        runtimeChunk: 'single',
        splitChunks: {
          chunks: 'all',
          cacheGroups: {
            default: false,
            vendors: false,
            // Vendor chunk for node_modules
            vendor: {
              name: 'vendor',
              chunks: 'all',
              test: /node_modules/,
              priority: 20
            },
            // Common chunk for shared modules
            common: {
              name: 'common',
              minChunks: 2,
              chunks: 'all',
              priority: 10,
              reuseExistingChunk: true,
              enforce: true
            },
            // Separate chunks for large libraries
            supabase: {
              name: 'supabase',
              test: /[\\/]node_modules[\\/]@supabase[\\/]/,
              chunks: 'all',
              priority: 30
            },
            charts: {
              name: 'charts',
              test: /[\\/]node_modules[\\/](chart\.js|react-chartjs-2)[\\/]/,
              chunks: 'all',
              priority: 30
            }
          }
        }
      }
      
      // Enable module concatenation (scope hoisting)
      config.optimization.concatenateModules = true
      
      // Minimize main bundle
      config.optimization.minimize = true
    }
    
    // Alias optimizations for smaller bundles
    config.resolve.alias = {
      ...config.resolve.alias,
      // Use production React builds
      'react': 'react/cjs/react.production.min.js',
      'react-dom': 'react-dom/cjs/react-dom.production.min.js',
      // Use smaller lodash imports
      'lodash': 'lodash-es'
    }
    
    // Add performance hints
    if (!isServer) {
      config.performance = {
        hints: 'warning',
        maxEntrypointSize: 512000, // 500 KB
        maxAssetSize: 512000 // 500 KB
      }
    }
    
    return config
  },
  
  // Image optimization
  images: {
    // Use modern image formats
    formats: ['image/avif', 'image/webp'],
    // Optimize image loading
    deviceSizes: [640, 768, 1024, 1280, 1536],
    imageSizes: [16, 32, 48, 64, 96, 128, 256],
    // Minimize image processing
    minimumCacheTTL: 60 * 60 * 24 * 365, // 1 year
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;"
  },
  
  // Headers for better caching
  async headers() {
    return [
      {
        source: '/_next/static/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable'
          }
        ]
      },
      {
        source: '/api/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=60, stale-while-revalidate=300'
          }
        ]
      }
    ]
  },
  
  // Output configuration
  output: 'standalone',
  
  // Disable x-powered-by header
  poweredByHeader: false,
  
  // Enable gzip compression
  compress: true,
  
  // Trailing slash configuration for consistent URLs
  trailingSlash: false,
  
  // Generate build ID based on git commit
  generateBuildId: async () => {
    return process.env.GIT_COMMIT_SHA || 'development'
  }
}

module.exports = nextConfig