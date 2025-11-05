'use server';

const LOGFLARE_SOURCE_TOKEN = process.env.LOGFLARE_SOURCE_TOKEN;
const LOGFLARE_API_KEY = process.env.LOGFLARE_API_KEY;
const LOGFLARE_ENDPOINT =
  process.env.LOGFLARE_INGESTION_URL ?? 'https://api.logflare.app/logs';

type LogLevel = 'debug' | 'info' | 'warning' | 'error' | 'critical';

export interface MonitoringEvent {
  event: string;
  level?: LogLevel;
  message?: string;
  tags?: string[];
  studioId?: string | null;
  context?: Record<string, unknown>;
}

export async function logMonitoringEvent(event: MonitoringEvent): Promise<void> {
  const { event: name, level = 'info', message, tags, studioId, context } = event;

  if (!LOGFLARE_SOURCE_TOKEN || !LOGFLARE_API_KEY) {
    if (process.env.NODE_ENV !== 'production') {
      console.info('[monitoring]', name, { level, message, tags, studioId, context });
    }
    return;
  }

  const payload = {
    source: LOGFLARE_SOURCE_TOKEN,
    log_entry: message ?? name,
    metadata: {
      event: name,
      level,
      tags,
      studioId,
      ...context,
      environment: process.env.VERCEL_ENV ?? process.env.NODE_ENV,
      timestamp: new Date().toISOString()
    }
  };

  try {
    const response = await fetch(LOGFLARE_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': LOGFLARE_API_KEY
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const fallbackMessage = await response.text().catch(() => 'Unknown error');
      console.warn('[monitoring] Failed to send logflare event', {
        status: response.status,
        body: fallbackMessage
      });
    }
  } catch (error) {
    console.warn('[monitoring] Unable to reach Logflare', error);
  }
}
