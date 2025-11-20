'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';

// Force dynamic rendering to prevent prerender errors with Supabase client
export const dynamic = 'force-dynamic';

export default function AuthCallbackHandler() {
  const [status, setStatus] = useState<'processing' | 'success' | 'error'>('processing');
  const [message, setMessage] = useState('Processing authentication...');
  const router = useRouter();

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // Check if we have tokens in the URL fragment
        const hashParams = new URLSearchParams(window.location.hash.substring(1));
        const accessToken = hashParams.get('access_token');
        const refreshToken = hashParams.get('refresh_token');
        const expiresIn = hashParams.get('expires_in');
        const providerToken = hashParams.get('provider_token');

        console.log('Client-side auth callback:', {
          hasAccessToken: !!accessToken,
          hasRefreshToken: !!refreshToken,
          expiresIn,
          hasProviderToken: !!providerToken
        });

        if (accessToken) {
          // We have tokens in the fragment - set the session
          const { data, error } = await supabase.auth.setSession({
            access_token: accessToken,
            refresh_token: refreshToken || '',
          });

          if (error) {
            console.error('Failed to set session:', error);
            setStatus('error');
            setMessage(`Authentication failed: ${error.message}`);
            setTimeout(() => router.push('/auth/signin'), 3000);
          } else if (data.session) {
            console.log('Session established successfully:', data.session.user?.email);
            setStatus('success');
            setMessage('Authentication successful! Redirecting...');
            // Redirect to dashboard after successful authentication
            setTimeout(() => router.push('/dashboard'), 1000);
          } else {
            setStatus('error');
            setMessage('No session data received');
            setTimeout(() => router.push('/auth/signin'), 3000);
          }
        } else {
          // No tokens found - this might be an error state
          console.error('No access token found in URL fragment');
          setStatus('error');
          setMessage('No authentication data found');
          setTimeout(() => router.push('/auth/signin'), 3000);
        }
      } catch (error) {
        console.error('Error handling auth callback:', error);
        setStatus('error');
        setMessage('An unexpected error occurred');
        setTimeout(() => router.push('/auth/signin'), 3000);
      }
    };

    handleAuthCallback();
  }, [supabase, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          {status === 'processing' && (
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          )}
          {status === 'success' && (
            <div className="rounded-full h-12 w-12 bg-green-100 flex items-center justify-center mx-auto">
              <svg className="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
          )}
          {status === 'error' && (
            <div className="rounded-full h-12 w-12 bg-red-100 flex items-center justify-center mx-auto">
              <svg className="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
          )}

          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {status === 'processing' && 'Completing Sign In'}
            {status === 'success' && 'Welcome!'}
            {status === 'error' && 'Authentication Error'}
          </h2>

          <p className="mt-2 text-center text-sm text-gray-600">
            {message}
          </p>

          {status === 'error' && (
            <div className="mt-4">
              <button
                onClick={() => router.push('/auth/signin')}
                className="text-purple-600 hover:text-purple-500 text-sm font-medium"
              >
                Return to Sign In
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}