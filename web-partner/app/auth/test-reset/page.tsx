'use client';

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';

function TestResetContent() {
  const searchParams = useSearchParams();
  const [logs, setLogs] = useState<string[]>([]);

  useEffect(() => {
    const addLog = (msg: string) => {
      console.log(msg);
      setLogs(prev => [...prev, `${new Date().toISOString()}: ${msg}`]);
    };

    addLog('=== TEST PAGE LOADED ===');
    addLog(`Current URL: ${window.location.href}`);
    addLog(`Search params: ${window.location.search}`);

    const params = new URLSearchParams(window.location.search);
    addLog(`token_hash: ${params.get('token_hash')?.substring(0, 20)}...`);
    addLog(`type: ${params.get('type')}`);
    addLog(`next: ${params.get('next')}`);

    // Test if we can reach the callback route
    const callbackUrl = `/auth/callback${window.location.search}`;
    addLog(`Would redirect to: ${callbackUrl}`);

  }, []);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg p-6">
        <h1 className="text-2xl font-bold mb-4">Password Reset Debug Page</h1>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-2">Current URL:</h2>
          <code className="block bg-gray-100 p-2 rounded text-sm break-all">
            {typeof window !== 'undefined' ? window.location.href : 'Loading...'}
          </code>
        </div>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-2">Parameters:</h2>
          <ul className="space-y-1">
            {typeof window !== 'undefined' && Array.from(new URLSearchParams(window.location.search)).map(([key, value]) => (
              <li key={key} className="bg-gray-100 p-2 rounded">
                <strong>{key}:</strong> {value.substring(0, 50)}{value.length > 50 ? '...' : ''}
              </li>
            ))}
          </ul>
        </div>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-2">Debug Logs:</h2>
          <div className="bg-black text-green-400 p-4 rounded font-mono text-xs space-y-1 max-h-96 overflow-auto">
            {logs.map((log, i) => (
              <div key={i}>{log}</div>
            ))}
          </div>
        </div>

        <div className="flex gap-4">
          <a
            href={`/auth/callback${typeof window !== 'undefined' ? window.location.search : ''}`}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Test Callback Route
          </a>
          <a
            href="/auth/forgot-password"
            className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
          >
            Back to Forgot Password
          </a>
        </div>
      </div>
    </div>
  );
}

export default function TestResetPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    }>
      <TestResetContent />
    </Suspense>
  );
}
