# Monitoring & Incident Playbook

This playbook formalises how we observe the partner portal in production, the alerts that page us, and the concrete steps to take when something degrades. It complements the existing regression checklist and should live alongside your deployment docs.

---

## Observability Stack

| Signal | Tooling | Notes |
| --- | --- | --- |
| Structured logs & alerts | [Logflare](https://logflare.app) | Errors and critical events from API routes are streamed via the new `logMonitoringEvent` helper. |
| Uptime / dependency checks | Vercel Cron → `/api/health` | Cron pings the health endpoint every 5 minutes and alerts when any dependency fails. |

Both layers are lightweight and can run in every environment (local will just log to the console if credentials are missing).

---

## Logflare Integration

1. **Create a source**  
   - Log into Logflare, create a project (if needed), then add a new *Source* named `hobbyist-web-partner`.  
   - Note the **Source Token** (UUID) and your **API Key**.

2. **Add environment variables (Vercel ➜ Settings ➜ Environment Variables)**  
   ```
   LOGFLARE_SOURCE_TOKEN=<source token from step 1>
   LOGFLARE_API_KEY=<logflare api key>
   # optional override if using a self-hosted Logflare instance
   LOGFLARE_INGESTION_URL=https://api.logflare.app/logs
   ```
   Redeploy after saving so the runtime picks up the secrets.

3. **Verify the pipeline**  
   - Trigger an error in a safe environment (e.g. hit `/api/dashboard/intelligence-data` without `studioId`).  
   - In Logflare, confirm a new log entry with `event=intelligence_data_fetch_failed` arrives.

4. **Create alert rules**  
   - Build a *Saved Search* matching critical events (recommended query):  
     ```
     metadata.event = 'health_check_failed'
     OR metadata.event = 'intelligence_data_fetch_failed'
     ```  
   - Attach the search to your alert destination (Slack webhook, email, PagerDuty, etc).  
   - Set the alert threshold to `>= 1 event in 5 minutes` to ensure rapid notification.

---

## Scheduled Health Check

### Endpoint

- Path: `GET /api/health`  
- Response (example):
  ```json
  {
    "status": "pass",
    "timestamp": "2025-11-04T15:30:00.000Z",
    "release": "38afc6d",
    "environment": "production",
    "checks": [
      { "component": "supabase", "status": "pass" },
      { "component": "logflare", "status": "pass" }
    ]
  }
  ```
- A failing check flips `"status"` to `"fail"` and records a message; the endpoint automatically emits a `health_check_failed` Logflare event.

### Vercel Cron configuration

1. Vercel Dashboard ➜ Project ➜ **Cron Jobs** ➜ *Add Job*.  
2. Schedule: `*/5 * * * *` (or tighter if needed).  
3. Endpoint: `https://<production-domain>/api/health`.  
4. Timeout: leave default (health probe is lightweight).  
5. Notifications: enable “Email on failure” and/or Slack integrations for redundant alerting.

If you operate multiple environments (preview/staging), add parallel cron definitions pointing at each base URL.

---

## Incident Response Playbook

1. **Triage**
   - Check Logflare for the failing event’s metadata (includes environment, release, and component).
   - Verify Supabase status: https://status.supabase.com.
   - Inspect the last deploy/build on Vercel for recent errors.

2. **Mitigation**
   - If Supabase credentials are missing or rotated, re-seed the env vars and redeploy.
   - For transient Supabase errors, re-run the health endpoint manually; if it persists >15 minutes escalate to Supabase support.
   - If Logflare is misconfigured, disable the failing cron alert temporarily (so it does not page repeatedly) and fix the credentials before re-enabling.

3. **Communication**
   - Post an update in the #ops channel (or equivalent) with: incident summary, affected systems, ETA, and assignee.
   - For customer impact, update the status page (if available) and pin the latest ETA.

4. **Post-incident**
   - Capture a short retro in the project’s Notion/Runbook, including detection time, resolution time, and any code/config changes.
   - Add new Logflare searches or health sub-checks if gaps were uncovered.

---

### Handy References

- `lib/monitoring/logflare.ts` – helper used by API routes to emit structured events.
- `app/api/health/route.ts` – JSON health probe consumed by Vercel Cron.
- `npm run type-check` – confirms TypeScript stays in sync after changing monitoring code.

Keep this document up to date as the stack evolves (e.g., if you add Redis, Stripe webhooks, etc., extend the health check and alert queries accordingly).
