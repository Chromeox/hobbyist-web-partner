Manual Payout Fallback SOP (Stripe)
==================================

Purpose
-------
Provide a standardized fallback workflow when the automated biweekly studio payout fails. The goal is to restore funds availability with Stripe manual transfers while preserving auditability, dual control, and customer transparency.

Pre-conditions
--------------
- Automation failure identified (scheduler outage, PSP rejection, reserve lock, etc.) with an open incident/ticket.
- Fallback request form submitted and approved by both Payments Ops and Finance.
- Stripe fallback restricted key stored in the secret manager and checked out by an authorized operator.
- Studio balance verified against the ledger, reserve remaining >= required minimum.

Live Checklist
--------------
1. **Verify details**
   - Confirm incident ID, studio identifiers, amount, and destination connected account.
   - Export the ledger payout details and attach to the incident.
2. **Run the helper script**
   - Ensure you are in the repository root (`HobbyApp/`), then execute:
     ```
     python3 scripts/manual_payout.py \
       --studio-id <uuid> \
       --studio-name "<Studio Name>" \
       --ledger-payout-id <ledger_uuid> \
       --incident-id INC-123 \
       --amount 1250.75 \
       --reserve-after 310.00 \
       --reason scheduler_outage \
       --destination-account acct_123 \
       --notes "Primary job timed out on PSP"
     ```
   - Set `STRIPE_FALLBACK_SECRET_KEY` in your shell before running. Use `--dry-run` for rehearsals.
   - Review the printed payload before confirming Stripe execution.
3. **Execute Stripe transfer**
   - If running live, allow the script to call Stripe. Capture the transfer ID from the response.
   - If manual API execution is needed, replicate the payload via `stripe` CLI or Postman and record the ID.
4. **Log the payout**
   - Insert the generated SQL into the `manual_payouts` table (adjust approver UUIDs before executing).
   - Upload the CLI output and Stripe response JSON to the incident ticket.
5. **Notify stakeholders**
   - Post the pre-filled Slack message in `#payments-alerts` (update approver names and incident link).
   - Send the prepared studio email using the shared support inbox. Confirm delivery in the ticket.
6. **Monitor settlement**
   - Track the transfer in Stripe > Balances > Transfers until the status is `paid`.
   - Update the incident timeline once settlement completes.
7. **Post-incident actions**
   - Restore automation, close the incident with a root-cause summary, and schedule the follow-up fixes.
   - Rotate the restricted Stripe key if it was exposed outside the secret manager.

Rehearsal Procedure
-------------------
- Run quarterly in Stripe test mode with seeded studio accounts.
- Use `--dry-run` first, then perform a full live call against the test environment.
- Validate audit log insertion (direct to test database or capture SQL) and confirm communications render correctly.
- Record start/end timestamps in the rehearsal ticket to track response time.

Monitoring Hooks
----------------
- Alert if more than one manual payout occurs within 30 days.
- PagerDuty notification for automation failures that generate fallback tickets.
- Certificate/credential renewal reminders at 30/14/7 days for Stripe payment-processing and merchant identity certs.

Security Controls
-----------------
- Restricted Stripe key has `transfers:create` + balance read scope only.
- Dual approval enforced by the fallback request form and incident workflow.
- Keys rotated after each real incident; access reviewed quarterly with Security.
- CLI script intentionally prints metadata and SQL insert to keep the audit trail consistent.

Reference Material
------------------
- Incident template: `docs/guides/payments_manual_payout_incident_template.md`.
- Sandbox rehearsal playbook: `docs/guides/payments_manual_payout_rehearsal.md`.
- Monitoring requirements: `docs/guides/payments_monitoring_requirements.md`.
