Payments Monitoring Requirements
================================

Scope
-----
Establish shared visibility into automated payouts, fallback usage, and credential health across Payments Ops, Finance, and Engineering.

Core Dashboards
---------------
1. **Payout Health**
   - Next scheduled biweekly run timestamp.
   - Job duration, success/error counts, retry metrics.
   - Total CAD processed per cycle vs. prior cycle.
2. **Fallback Activity**
   - Manual payout count (rolling 30 days).
   - Total CAD routed via fallback.
   - Time from detection to manual transfer completion.
3. **Reserves & Balances**
   - Aggregate reserve balance.
   - Studios nearing reserve thresholds (< 20% buffer).
   - Outstanding payouts held due to reserve caps.
4. **Credential Expiry**
   - Apple Pay payment-processing certificate expiry dates.
   - Stripe restricted key rotation dates.
   - PSP webhook signing secret age.

Alerting Rules
--------------
- **Automation failure:** payout job exits non-zero, takes > 30 minutes, or processes < 90% of scheduled studios. PagerDuty SEV-2.
- **Fallback volume:** more than one manual payout in 30 days or CAD fallback > 5% of automated volume. Slack + Jira.
- **Certificate/key expiry:** 30/14/7-day reminders via Slack; escalate to PagerDuty at 3 days if still unresolved.
- **Reserve breach:** reserve balance projected below policy threshold within next payout cycle. Email + Ops channel.

Data Sources
------------
- Job scheduler metrics (Sidekiq/Chronos/Airflow) exported to Grafana/Looker.
- Ledger database views for scheduled payouts and reserves.
- `manual_payouts` table for fallback events.
- Stripe / PSP API telemetry (transfers, balance history).
- Secrets manager metadata for credential creation timestamps.

Ownership
---------
- **Payments Engineering:** maintain dashboards, instrumentation, alert tuning.
- **Payments Ops:** respond to alerts, manage fallback SOP, update incident reports.
- **Finance:** reconcile payouts vs. ledger, review reserve alerts weekly.
- **Security:** oversee credential rotation schedule and access reviews.

Review Cadence
--------------
- Weekly stand-up snapshot (15 minutes) covering payout health and open alerts.
- Quarterly deep dive on fallback metrics and automation hardening roadmap.
- Post-incident retrospective includes dashboard/alert adjustments.
