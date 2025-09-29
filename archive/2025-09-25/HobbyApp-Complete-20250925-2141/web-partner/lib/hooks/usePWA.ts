/**
 * PWA Hook for Progressive Web App features
 * Handles installation, updates, and offline detection
 */

import { useEffect, useState, useCallback } from 'react';

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

interface PWAState {
  isInstallable: boolean;
  isInstalled: boolean;
  isOffline: boolean;
  isUpdateAvailable: boolean;
  installPrompt: BeforeInstallPromptEvent | null;
  registration: ServiceWorkerRegistration | null;
}

interface PWAActions {
  install: () => Promise<boolean>;
  update: () => void;
  clearCache: () => Promise<void>;
  checkForUpdates: () => Promise<void>;
}

export function usePWA(): PWAState & PWAActions {
  const [state, setState] = useState<PWAState>({
    isInstallable: false,
    isInstalled: false,
    isOffline: !navigator.onLine,
    isUpdateAvailable: false,
    installPrompt: null,
    registration: null
  });

  // Check if app is installed
  const checkInstalled = useCallback(() => {
    // Check if running in standalone mode
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
                        (window.navigator as any).standalone ||
                        document.referrer.includes('android-app://');
    
    setState(prev => ({ ...prev, isInstalled: isStandalone }));
  }, []);

  // Install the PWA
  const install = useCallback(async (): Promise<boolean> => {
    if (!state.installPrompt) {
      console.log('[PWA] No install prompt available');
      return false;
    }

    try {
      // Show the install prompt
      await state.installPrompt.prompt();
      
      // Wait for the user choice
      const { outcome } = await state.installPrompt.userChoice;
      
      if (outcome === 'accepted') {
        console.log('[PWA] App installed successfully');
        setState(prev => ({
          ...prev,
          isInstalled: true,
          isInstallable: false,
          installPrompt: null
        }));
        
        // Track installation
        if (typeof window !== 'undefined' && (window as any).gtag) {
          (window as any).gtag('event', 'pwa_install', {
            event_category: 'PWA',
            event_label: 'Install'
          });
        }
        
        return true;
      } else {
        console.log('[PWA] Installation dismissed');
        return false;
      }
    } catch (error) {
      console.error('[PWA] Installation failed:', error);
      return false;
    }
  }, [state.installPrompt]);

  // Update the service worker
  const update = useCallback(() => {
    if (state.registration?.waiting) {
      // Tell the waiting service worker to take control
      state.registration.waiting.postMessage({ type: 'SKIP_WAITING' });
      
      // Reload once the new service worker takes control
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        window.location.reload();
      });
    }
  }, [state.registration]);

  // Clear all caches
  const clearCache = useCallback(async () => {
    if ('caches' in window) {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map(name => caches.delete(name)));
      console.log('[PWA] All caches cleared');
      
      // Also tell service worker to clear its caches
      if (navigator.serviceWorker.controller) {
        navigator.serviceWorker.controller.postMessage({ type: 'CLEAR_CACHE' });
      }
    }
  }, []);

  // Check for service worker updates
  const checkForUpdates = useCallback(async () => {
    if (state.registration) {
      try {
        await state.registration.update();
        console.log('[PWA] Checked for updates');
      } catch (error) {
        console.error('[PWA] Update check failed:', error);
      }
    }
  }, [state.registration]);

  useEffect(() => {
    // Check if PWA is supported
    if (typeof window === 'undefined') return;

    let deferredPrompt: BeforeInstallPromptEvent | null = null;

    // Handle install prompt
    const handleBeforeInstallPrompt = (e: Event) => {
      // Prevent the default prompt
      e.preventDefault();
      
      // Store the event for later use
      deferredPrompt = e as BeforeInstallPromptEvent;
      
      setState(prev => ({
        ...prev,
        isInstallable: true,
        installPrompt: deferredPrompt
      }));
      
      console.log('[PWA] Install prompt captured');
    };

    // Handle app installed
    const handleAppInstalled = () => {
      console.log('[PWA] App was installed');
      setState(prev => ({
        ...prev,
        isInstalled: true,
        isInstallable: false,
        installPrompt: null
      }));
    };

    // Handle online/offline status
    const handleOnline = () => {
      setState(prev => ({ ...prev, isOffline: false }));
      console.log('[PWA] Back online');
    };

    const handleOffline = () => {
      setState(prev => ({ ...prev, isOffline: true }));
      console.log('[PWA] Gone offline');
    };

    // Register service worker and set up listeners
    const setupServiceWorker = async () => {
      if ('serviceWorker' in navigator) {
        try {
          const registration = await navigator.serviceWorker.register('/service-worker.js');
          
          setState(prev => ({ ...prev, registration }));
          
          // Check for updates every hour
          const updateInterval = setInterval(() => {
            registration.update();
          }, 60 * 60 * 1000);

          // Handle updates
          registration.addEventListener('updatefound', () => {
            const newWorker = registration.installing;
            
            if (newWorker) {
              newWorker.addEventListener('statechange', () => {
                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                  // New content available
                  setState(prev => ({ ...prev, isUpdateAvailable: true }));
                  console.log('[PWA] Update available');
                  
                  // Show update notification
                  if (Notification.permission === 'granted') {
                    new Notification('Update Available', {
                      body: 'A new version of Hobbyist is available. Click to update.',
                      icon: '/icons/icon-192x192.png',
                      badge: '/icons/badge-72x72.png',
                      tag: 'update-notification'
                    }).addEventListener('click', update);
                  }
                }
              });
            }
          });

          return () => clearInterval(updateInterval);
        } catch (error) {
          console.error('[PWA] Service worker registration failed:', error);
        }
      }
    };

    // Set up event listeners
    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    window.addEventListener('appinstalled', handleAppInstalled);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Initial checks
    checkInstalled();
    setupServiceWorker();

    // Request notification permission if needed
    if ('Notification' in window && Notification.permission === 'default') {
      // Delay permission request to avoid being too aggressive
      setTimeout(() => {
        Notification.requestPermission();
      }, 30000); // 30 seconds after page load
    }

    // Cleanup
    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
      window.removeEventListener('appinstalled', handleAppInstalled);
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [checkInstalled, update]);

  return {
    ...state,
    install,
    update,
    clearCache,
    checkForUpdates
  };
}

/**
 * Hook for push notifications
 */
export function usePushNotifications() {
  const [isSupported, setIsSupported] = useState(false);
  const [isSubscribed, setIsSubscribed] = useState(false);
  const [subscription, setSubscription] = useState<PushSubscription | null>(null);

  useEffect(() => {
    if ('PushManager' in window && 'serviceWorker' in navigator) {
      setIsSupported(true);
      checkSubscription();
    }
  }, []);

  const checkSubscription = async () => {
    try {
      const registration = await navigator.serviceWorker.ready;
      const subscription = await registration.pushManager.getSubscription();
      
      setIsSubscribed(!!subscription);
      setSubscription(subscription);
    } catch (error) {
      console.error('[Push] Failed to check subscription:', error);
    }
  };

  const subscribe = async () => {
    try {
      const registration = await navigator.serviceWorker.ready;
      
      // Get public key from server
      const response = await fetch('/api/push/vapid-key');
      const { publicKey } = await response.json();
      
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: publicKey
      });
      
      // Send subscription to server
      await fetch('/api/push/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscription)
      });
      
      setIsSubscribed(true);
      setSubscription(subscription);
      
      console.log('[Push] Subscribed successfully');
      return true;
    } catch (error) {
      console.error('[Push] Subscription failed:', error);
      return false;
    }
  };

  const unsubscribe = async () => {
    try {
      if (subscription) {
        await subscription.unsubscribe();
        
        // Notify server
        await fetch('/api/push/unsubscribe', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ endpoint: subscription.endpoint })
        });
        
        setIsSubscribed(false);
        setSubscription(null);
        
        console.log('[Push] Unsubscribed successfully');
        return true;
      }
      return false;
    } catch (error) {
      console.error('[Push] Unsubscribe failed:', error);
      return false;
    }
  };

  return {
    isSupported,
    isSubscribed,
    subscription,
    subscribe,
    unsubscribe
  };
}