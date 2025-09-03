'use client';

import { useEffect, useState } from 'react';

export default function OfflinePage() {
  const [cachedPages, setCachedPages] = useState<string[]>([]);
  const [isOnline, setIsOnline] = useState(false);

  useEffect(() => {
    // Check online status
    const updateOnlineStatus = () => {
      setIsOnline(navigator.onLine);
    };

    // Get cached pages from service worker
    const getCachedPages = async () => {
      if ('caches' in window) {
        try {
          const cacheNames = await caches.keys();
          const pages: string[] = [];
          
          for (const name of cacheNames) {
            const cache = await caches.open(name);
            const requests = await cache.keys();
            
            requests.forEach(request => {
              const url = new URL(request.url);
              if (url.pathname.startsWith('/dashboard')) {
                pages.push(url.pathname);
              }
            });
          }
          
          setCachedPages([...new Set(pages)]);
        } catch (error) {
          console.error('Failed to get cached pages:', error);
        }
      }
    };

    updateOnlineStatus();
    getCachedPages();

    // Listen for online/offline events
    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);

    return () => {
      window.removeEventListener('online', updateOnlineStatus);
      window.removeEventListener('offline', updateOnlineStatus);
    };
  }, []);

  const tryReconnect = () => {
    window.location.reload();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        {/* Glass morphism card */}
        <div className="backdrop-blur-xl bg-white/10 rounded-2xl p-8 shadow-2xl border border-white/20">
          {/* Status icon */}
          <div className="flex justify-center mb-6">
            <div className="relative">
              <div className="w-24 h-24 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
                <svg
                  className="w-12 h-12 text-white"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414"
                  />
                </svg>
              </div>
              {/* Pulsing animation */}
              <div className="absolute inset-0 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 animate-ping opacity-20" />
            </div>
          </div>

          {/* Content */}
          <div className="text-center">
            <h1 className="text-3xl font-bold text-white mb-2">
              You're Offline
            </h1>
            <p className="text-white/70 mb-8">
              {isOnline 
                ? "Your internet connection was restored, but the page failed to load."
                : "Please check your internet connection and try again."
              }
            </p>

            {/* Action buttons */}
            <button
              onClick={tryReconnect}
              className="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white font-semibold py-3 px-6 rounded-xl hover:shadow-lg transition-all duration-300 transform hover:scale-105 mb-4"
            >
              Try Again
            </button>

            {/* Cached pages */}
            {cachedPages.length > 0 && (
              <div className="mt-8">
                <p className="text-white/70 text-sm mb-4">
                  These pages are available offline:
                </p>
                <div className="space-y-2">
                  {cachedPages.slice(0, 5).map(page => (
                    <a
                      key={page}
                      href={page}
                      className="block w-full backdrop-blur-xl bg-white/5 text-white/90 py-2 px-4 rounded-lg hover:bg-white/10 transition-all duration-300 text-sm"
                    >
                      {page.replace('/dashboard/', '').replace('/', ' › ')}
                    </a>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Tips */}
          <div className="mt-8 pt-6 border-t border-white/20">
            <p className="text-white/60 text-xs text-center">
              💡 Tip: The Hobbyist app works offline and will sync your changes when you reconnect.
            </p>
          </div>
        </div>

        {/* Status indicator */}
        <div className="mt-6 text-center">
          <div className="inline-flex items-center space-x-2">
            <div className={`w-2 h-2 rounded-full ${isOnline ? 'bg-green-500' : 'bg-red-500'} animate-pulse`} />
            <span className="text-white/60 text-sm">
              {isOnline ? 'Connection restored' : 'No connection'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}