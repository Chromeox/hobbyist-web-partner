/** @type {import('next').NextConfig} */

const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

// HTTP/2 Server Push and Performance Configuration
const nextConfig = {
  reactStrictMode: true,

  // Enable experimental features for performance
  experimental: {
    optimizeCss: true, // CSS optimization
    optimizePackageImports: [
      '@supabase/supabase-js', 
      '@radix-ui/react-dialog',
      '@radix-ui/react-dropdown-menu',
      '@radix-ui/react-select',
      '@radix-ui/react-tabs',
      '@radix-ui/react-toast',
      'lucide-react',
      'framer-motion',
      'chart.js',
      'recharts'
    ],
    webVitalsAttribution: ['CLS', 'LCP', 'FCP', 'FID', 'TTFB'],
  },
  
  // Compiler options for smaller bundles
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
    reactRemoveProperties: process.env.NODE_ENV === 'production',
  },
  
  // Image optimization (updated for Next.js 16)
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'mcjqvdzdhtcvbrejvrtp.supabase.co',
        port: '',
        pathname: '/**',
      },
    ],
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 60 * 60 * 24 * 365, // 1 year
  },
  
  // Turbopack configuration for Next.js 16
  turbopack: {},
  
  // Headers for HTTP/2 Server Push and resource hints
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          // HTTP/2 Server Push critical resources
          {
            key: 'Link',
            value: [
              '</fonts/inter-var.woff2>; rel=preload; as=font; type=font/woff2; crossorigin',
              '</_next/static/css/app.css>; rel=preload; as=style',
              '</_next/static/js/app.js>; rel=preload; as=script',
              '</manifest.json>; rel=preload; as=fetch',
              '</service-worker.js>; rel=serviceworker',
            ].join(', ')
          },
          
          // Resource hints for better performance
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on'
          },
          
          // Security headers
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin'
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(self), interest-cohort=()'
          },
        ],
      },
      
      // Specific headers for dynamic pages
      {
        source: '/dashboard/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'private, no-cache, no-store, must-revalidate'
          },
          {
            key: 'Link',
            value: [
              '</api/classes>; rel=prefetch',
              '</api/bookings>; rel=prefetch',
              '</api/instructors>; rel=prefetch',
            ].join(', ')
          }
        ],
      },
      
      // Service Worker specific headers
      {
        source: '/service-worker.js',
        headers: [
          {
            key: 'Service-Worker-Allowed',
            value: '/'
          },
          {
            key: 'Cache-Control',
            value: 'no-cache, no-store, must-revalidate'
          }
        ],
      },
      
      // PWA manifest headers
      {
        source: '/manifest.json',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=86400' // Cache for 1 day
          }
        ],
      },
      
      // WebAssembly headers
      {
        source: '/wasm/:path*',
        headers: [
          {
            key: 'Content-Type',
            value: 'application/wasm'
          },
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable'
          }
        ],
      }
    ];
  },
  
  // Redirects for PWA
  async redirects() {
    return [
      {
        source: '/home',
        destination: '/dashboard',
        permanent: true,
      },
      {
        source: '/app',
        destination: '/dashboard',
        permanent: false,
      }
    ];
  },
  
  // Rewrites for API optimization
  async rewrites() {
    return [
      // Proxy Supabase requests for better caching
      {
        source: '/api/supabase/:path*',
        destination: 'https://mcjqvdzdhtcvbrejvrtp.supabase.co/:path*',
      }
    ];
  },
  
  // Webpack configuration for advanced optimizations
  webpack: (config, { dev, isServer }) => {
    // Enable WebAssembly
    config.experiments = {
      ...config.experiments,
      asyncWebAssembly: true,
      layers: true,
    };
    
    // Add WebAssembly loader
    config.module.rules.push({
      test: /\.wasm$/,
      type: 'asset/resource',
    });
    
    // Production optimizations
    if (!dev && !isServer) {
      // Enable module concatenation (scope hoisting)
      config.optimization.concatenateModules = true;
      
      // Split chunks for better caching
      config.optimization.splitChunks = {
        chunks: 'all',
        cacheGroups: {
          default: false,
          vendors: false,
          framework: {
            name: 'framework',
            chunks: 'all',
            test: /(?<!node_modules.*)[\\/]node_modules[\\/](react|react-dom|scheduler|prop-types|use-sync-external-store)[\\/]/,
            priority: 40,
            enforce: true,
          },
          lib: {
            test(module) {
              return module.size() > 160000 &&
                /node_modules[/\\]/.test(module.identifier());
            },
            name(module) {
              const crypto = require('crypto');
              const hash = crypto.createHash('sha1');
              hash.update(module.identifier());
              return hash.digest('hex').substring(0, 8);
            },
            priority: 30,
            minChunks: 1,
            reuseExistingChunk: true,
          },
          commons: {
            name: 'commons',
            chunks: 'all',
            minChunks: 2,
            priority: 20,
          },
        },
      };
      
      // Minimize main bundle
      config.optimization.minimize = true;
    }
    
    // Add aliases for cleaner imports
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': './app',
      '@components': './app/components',
      '@lib': './lib',
      '@hooks': './lib/hooks',
      '@services': './lib/services',
      '@utils': './lib/utils',
      '@types': './types',
    };
    
    return config;
  },
  
  // Environment variables to expose to the browser
  env: {
    NEXT_PUBLIC_APP_VERSION: process.env.npm_package_version || '1.0.0',
    NEXT_PUBLIC_ENABLE_PWA: 'true',
    NEXT_PUBLIC_ENABLE_WASM: 'true',
    NEXT_PUBLIC_ENABLE_WORKERS: 'true',
  },
  
  // Disable x-powered-by header
  poweredByHeader: false,
  
  // Enable source maps in production for error tracking
  productionBrowserSourceMaps: process.env.ENABLE_SOURCE_MAPS === 'true',
}

module.exports = withBundleAnalyzer(nextConfig)
