Manual Payout Incident Template
===============================

Use this template in PagerDuty, Jira, or Notion to document automation outages that require fallback payouts.

Metadata
--------
- **Incident ID:** `INC-0000`
- **Severity:** `SEV-2` / `SEV-3`
- **Status:** `Open`
- **Owner:** `@oncall-payments`
- **Start time:** `2024-10-10T16:05Z`
- **Detection source:** `payout_scheduler_latency` alert / manual report

Summary
-------
Provide a concise statement of the failure and impact.
Example: `Biweekly payout job for 2024-10-10 failed after PSP timeouts. 34 studios unpaid, CAD 182k delayed, manual payouts initiated.`

Impact
------
- Studios affected: `NN`
- Total CAD delayed: `$XXX,XXX`
- Reserve impact: `None` / `Reduced reserve by CAD X`
- Customer support tickets: `#PAY-####`

Detection
---------
- Alert name or monitoring dashboard section.
- Timestamp of first alert / manual report.

Timeline
--------
- `16:05` – Alert fired (PagerDuty)
- `16:12` – Ops acknowledged incident
- `16:20` – Root cause investigation started
- `16:45` – Manual payouts approved
- `17:05` – Stripe transfers completed
- `17:15` – Studios notified
- `18:40` – Automation job restored

Root Cause
----------
Summarize the technical reason (PSP outage, code regression, credential expiry, etc.).

Mitigation
----------
List actions taken with timestamps. Include manual payouts, retries, PSP escalations, feature flags toggled.

Follow-up Actions
-----------------
1. `Owner` – Task description – Due date
2. `Owner` – Task description – Due date

Customer Communications
-----------------------
- Studio email: link to Zendesk macro or outgoing message.
- In-app banner / status page: link or status summary.

Lessons Learned
---------------
- Monitoring gaps
- Process improvements
- Tooling enhancements

Attachments
-----------
- Stripe transfer IDs
- Ledger export links
- CLI output and SQL insert confirmations
- Related pull requests / fixes
