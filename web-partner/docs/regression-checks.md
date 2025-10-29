# Partner Dashboard Regression Checks

This guide documents where the automated QA utilities and supporting runbooks live so the partner dashboard team has a single place to start.

## Script Location
- `web-partner/scripts/partner-regression-check.js` — Node script that exercises the live Supabase API coverage for pricing, classes, payouts, messaging, and reviews.
  - Requires a populated `web-partner/.env.local` with Supabase service credentials.
  - Writes Markdown reports to `web-partner/test-results/` with timestamped filenames.
  - Run with `node scripts/partner-regression-check.js` from the `web-partner` directory.

## Operational Runbooks
- High-level payment and payout runbooks live in the monorepo root under `docs/guides/`.
  - `manual_payout_sop.md`, `payments_manual_payout_rehearsal.md`, `payments_manual_payout_incident_template.md`, `payments_monitoring_requirements.md`.
- Reference these guides when regression output flags payout issues or when manual intervention is required.

## Suggested Workflow
1. Run the regression script prior to each partner dashboard release.
2. Review the generated report for `FAIL` / `WARN` entries and log findings in the release checklist.
3. If payouts regress, follow the guides in `docs/guides/` for mitigation and communication.
4. Archive the report in the release notes or attach to the incident ticket if issues persist.

Keeping the automation script and guides in these well-defined locations ensures future contributors know where to look for QA tooling and operational procedures.
