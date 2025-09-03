/**
 * Hobbyist Platform Service Worker
 * 
 * Features:
 * - Intelligent caching strategy
 * - Offline support for critical pages
 * - Background sync for bookings
 * - Push notifications
 * - Performance optimization via cache-first strategies
 */

const CACHE_VERSION = 'v1.0.0';
const CACHE_NAMES = {
  STATIC: `hobbyist-static-${CACHE_VERSION}`,
  DYNAMIC: `hobbyist-dynamic-${CACHE_VERSION}`,
  IMAGES: `hobbyist-images-${CACHE_VERSION}`,
  API: `hobbyist-api-${CACHE_VERSION}`
};

// Critical resources to cache immediately
const STATIC_ASSETS = [
  '/',
  '/dashboard',
  '/offline',
  '/manifest.json',
  '/_next/static/css/app.css',
  '/_next/static/js/app.js',
  '/fonts/inter-var.woff2',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// API endpoints to cache with network-first strategy
const API_ROUTES = [
  '/api/classes',
  '/api/instructors',
  '/api/categories',
  '/api/studios'
];

// Cache strategies
const CACHE_STRATEGIES = {
  CACHE_FIRST: 'cache-first',
  NETWORK_FIRST: 'network-first',
  CACHE_ONLY: 'cache-only',
  NETWORK_ONLY: 'network-only',
  STALE_WHILE_REVALIDATE: 'stale-while-revalidate'
};

// Install event - cache critical resources
self.addEventListener('install', (event) => {
  console.log('[ServiceWorker] Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAMES.STATIC)
      .then((cache) => {
        console.log('[ServiceWorker] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => self.skipWaiting()) // Activate immediately
  );
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  console.log('[ServiceWorker] Activating...');
  
  event.waitUntil(
    Promise.all([
      // Clean old caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((cacheName) => {
              return !Object.values(CACHE_NAMES).includes(cacheName);
            })
            .map((cacheName) => {
              console.log('[ServiceWorker] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            })
        );
      }),
      // Take control of all clients
      self.clients.claim()
    ])
  );
});

// Fetch event - intelligent routing
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip cross-origin requests
  if (url.origin !== location.origin) {
    return;
  }
  
  // Determine cache strategy based on request
  let strategy = determineStrategy(request);
  
  event.respondWith(
    handleRequest(request, strategy)
  );
});

// Determine caching strategy based on request type
function determineStrategy(request) {
  const url = new URL(request.url);
  const path = url.pathname;
  
  // Images - cache first with fallback
  if (request.destination === 'image' || /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(path)) {
    return CACHE_STRATEGIES.CACHE_FIRST;
  }
  
  // API calls - network first with cache fallback
  if (path.startsWith('/api/') || path.includes('supabase')) {
    return CACHE_STRATEGIES.NETWORK_FIRST;
  }
  
  // Static assets - cache first
  if (/\.(js|css|woff2?)$/i.test(path) || path.includes('/_next/static/')) {
    return CACHE_STRATEGIES.CACHE_FIRST;
  }
  
  // HTML pages - stale while revalidate
  if (request.mode === 'navigate' || request.headers.get('accept')?.includes('text/html')) {
    return CACHE_STRATEGIES.STALE_WHILE_REVALIDATE;
  }
  
  // Default - network first
  return CACHE_STRATEGIES.NETWORK_FIRST;
}

// Handle request with specified strategy
async function handleRequest(request, strategy) {
  switch (strategy) {
    case CACHE_STRATEGIES.CACHE_FIRST:
      return cacheFirst(request);
    
    case CACHE_STRATEGIES.NETWORK_FIRST:
      return networkFirst(request);
    
    case CACHE_STRATEGIES.STALE_WHILE_REVALIDATE:
      return staleWhileRevalidate(request);
    
    case CACHE_STRATEGIES.CACHE_ONLY:
      return cacheOnly(request);
    
    case CACHE_STRATEGIES.NETWORK_ONLY:
      return networkOnly(request);
    
    default:
      return networkFirst(request);
  }
}

// Cache-first strategy
async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAMES.DYNAMIC);
  const cached = await cache.match(request);
  
  if (cached) {
    return cached;
  }
  
  try {
    const response = await fetch(request);
    
    // Cache successful responses
    if (response.ok) {
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    // Return offline page for navigation requests
    if (request.mode === 'navigate') {
      return caches.match('/offline');
    }
    throw error;
  }
}

// Network-first strategy
async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAMES.DYNAMIC);
  
  try {
    const response = await fetchWithTimeout(request, 3000); // 3 second timeout
    
    // Cache successful responses
    if (response.ok) {
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    
    if (cached) {
      return cached;
    }
    
    // Return offline page for navigation requests
    if (request.mode === 'navigate') {
      return caches.match('/offline');
    }
    
    throw error;
  }
}

// Stale-while-revalidate strategy
async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_NAMES.DYNAMIC);
  const cached = await cache.match(request);
  
  // Return cached immediately if available
  const fetchPromise = fetch(request).then((response) => {
    // Update cache in background
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  });
  
  return cached || fetchPromise;
}

// Cache-only strategy
async function cacheOnly(request) {
  const cache = await caches.open(CACHE_NAMES.STATIC);
  const cached = await cache.match(request);
  
  if (cached) {
    return cached;
  }
  
  // Return 404 response
  return new Response('Not found in cache', { status: 404 });
}

// Network-only strategy
async function networkOnly(request) {
  return fetch(request);
}

// Fetch with timeout
function fetchWithTimeout(request, timeout = 5000) {
  return Promise.race([
    fetch(request),
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Request timeout')), timeout)
    )
  ]);
}

// Background sync for failed bookings
self.addEventListener('sync', (event) => {
  console.log('[ServiceWorker] Background sync triggered');
  
  if (event.tag === 'sync-bookings') {
    event.waitUntil(syncBookings());
  }
});

// Sync failed bookings
async function syncBookings() {
  try {
    // Get pending bookings from IndexedDB
    const pendingBookings = await getPendingBookings();
    
    for (const booking of pendingBookings) {
      try {
        const response = await fetch('/api/bookings', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(booking)
        });
        
        if (response.ok) {
          await removePendingBooking(booking.id);
          
          // Notify user of successful sync
          self.registration.showNotification('Booking Confirmed!', {
            body: `Your booking for ${booking.className} has been confirmed.`,
            icon: '/icons/icon-192x192.png',
            badge: '/icons/badge-72x72.png',
            vibrate: [200, 100, 200]
          });
        }
      } catch (error) {
        console.error('[ServiceWorker] Failed to sync booking:', error);
      }
    }
  } catch (error) {
    console.error('[ServiceWorker] Sync failed:', error);
  }
}

// Push notification handling
self.addEventListener('push', (event) => {
  console.log('[ServiceWorker] Push received');
  
  let data = {};
  
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = {
        title: 'Hobbyist',
        body: event.data.text()
      };
    }
  }
  
  const options = {
    body: data.body || 'You have a new notification',
    icon: data.icon || '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    vibrate: data.vibrate || [200, 100, 200],
    data: data.data || {},
    actions: data.actions || [
      {
        action: 'view',
        title: 'View'
      },
      {
        action: 'dismiss',
        title: 'Dismiss'
      }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'Hobbyist', options)
  );
});

// Notification click handling
self.addEventListener('notificationclick', (event) => {
  console.log('[ServiceWorker] Notification clicked');
  
  event.notification.close();
  
  if (event.action === 'view' || !event.action) {
    const urlToOpen = event.notification.data?.url || '/dashboard';
    
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then((windowClients) => {
          // Check if there's already a window/tab open
          for (const client of windowClients) {
            if (client.url === urlToOpen && 'focus' in client) {
              return client.focus();
            }
          }
          // Open new window if not found
          if (clients.openWindow) {
            return clients.openWindow(urlToOpen);
          }
        })
    );
  }
});

// Message handling for client communication
self.addEventListener('message', (event) => {
  console.log('[ServiceWorker] Message received:', event.data);
  
  if (event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => caches.delete(cacheName))
        );
      })
    );
  }
  
  if (event.data.type === 'CACHE_URLS') {
    event.waitUntil(
      caches.open(CACHE_NAMES.DYNAMIC).then((cache) => {
        return cache.addAll(event.data.urls);
      })
    );
  }
});

// IndexedDB helpers for offline booking storage
function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('HobbyistOffline', 1);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      
      if (!db.objectStoreNames.contains('pendingBookings')) {
        db.createObjectStore('pendingBookings', { keyPath: 'id' });
      }
    };
  });
}

async function getPendingBookings() {
  const db = await openDB();
  const transaction = db.transaction(['pendingBookings'], 'readonly');
  const store = transaction.objectStore('pendingBookings');
  
  return new Promise((resolve, reject) => {
    const request = store.getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function removePendingBooking(id) {
  const db = await openDB();
  const transaction = db.transaction(['pendingBookings'], 'readwrite');
  const store = transaction.objectStore('pendingBookings');
  
  return new Promise((resolve, reject) => {
    const request = store.delete(id);
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

// Performance monitoring
self.addEventListener('fetch', (event) => {
  const startTime = performance.now();
  
  event.waitUntil(
    event.respondWith.then(() => {
      const duration = performance.now() - startTime;
      
      // Log slow requests
      if (duration > 1000) {
        console.warn(`[ServiceWorker] Slow request: ${event.request.url} took ${duration}ms`);
      }
    })
  );
});