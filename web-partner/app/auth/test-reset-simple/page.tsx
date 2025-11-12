'use client';

import { useEffect, useState, Suspense } from 'react';

function SimpleTestContent() {
  const [info, setInfo] = useState<string>('Loading...');

  useEffect(() => {
    const url = window.location.href;
    const params = new URLSearchParams(window.location.search);

    const tokenHash = params.get('token_hash');
    const type = params.get('type');
    const next = params.get('next');

    const output = `
PASSWORD RESET DEBUG
====================

Current URL:
${url}

Parameters Found:
- token_hash: ${tokenHash ? tokenHash.substring(0, 30) + '...' : 'MISSING'}
- type: ${type || 'MISSING'}
- next: ${next || 'MISSING'}

Callback URL would be:
/auth/callback${window.location.search}

====================
    `.trim();

    setInfo(output);
    console.log(output);
  }, []);

  return (
    <html>
      <body style={{ fontFamily: 'monospace', padding: '20px', backgroundColor: '#f0f0f0' }}>
        <pre style={{
          backgroundColor: 'white',
          padding: '20px',
          border: '2px solid #333',
          whiteSpace: 'pre-wrap',
          fontSize: '14px'
        }}>
          {info}
        </pre>
        <div style={{ marginTop: '20px' }}>
          <a
            href={typeof window !== 'undefined' ? `/auth/callback${window.location.search}` : '#'}
            style={{
              display: 'inline-block',
              padding: '10px 20px',
              backgroundColor: '#0070f3',
              color: 'white',
              textDecoration: 'none',
              borderRadius: '5px',
              marginRight: '10px'
            }}
          >
            TEST CALLBACK ROUTE →
          </a>
          <a
            href="/auth/forgot-password"
            style={{
              display: 'inline-block',
              padding: '10px 20px',
              backgroundColor: '#666',
              color: 'white',
              textDecoration: 'none',
              borderRadius: '5px'
            }}
          >
            ← Back to Forgot Password
          </a>
        </div>
      </body>
    </html>
  );
}

export default function SimpleTestPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <SimpleTestContent />
    </Suspense>
  );
}
