Manual Payout Rehearsal Playbook
================================

Objective
---------
Validate quarterly that the Stripe fallback SOP, tooling, and communications flow function end-to-end without touching production data.

Scheduling
----------
- Frequency: once per quarter, scheduled at least one week before a live payout cycle.
- Duration: 45 minutes reserved on the shared Ops calendar (`Payments Fallback Rehearsal`).
- Participants: Payments Ops lead, Finance representative, Payments Engineer on call.

Environment Setup
-----------------
1. Stripe test mode with two connected accounts seeded (`acct_test_studio_a`, `acct_test_studio_b`).
2. Test ledger dataset with realistic balances and reserves.
3. `STRIPE_FALLBACK_SECRET_KEY` pointing to the test restricted key.
4. Dedicated sandbox database or schema for the `manual_payouts` table.
5. Slack `#payments-rehearsal` channel and email alias (e.g., `payments-rehearsal@hobbyist.com`) for notifications.

Runbook
-------
1. **Kickoff**
   - Operator opens the latest SOP in `docs/guides/manual_payout_sop.md`.
   - Confirm rehearsal ticket ID (e.g., `REH-2024-Q4`) is open.
2. **Simulate failure**
   - Disable the sandbox automation job or inject a failure flag so the ledger marks payouts as pending.
   - Document timestamp in rehearsal ticket.
3. **Submit fallback request**
   - Populate the internal form with test values (use `stability` reason).
   - Ensure dual approval is recorded.
4. **Execute script**
   - Run:
     ```
     STRIPE_FALLBACK_SECRET_KEY=<test_key> \
     python3 scripts/manual_payout.py \
       --studio-id 11111111-1111-1111-1111-111111111111 \
       --studio-name "Test Studio A" \
       --ledger-payout-id 22222222-2222-2222-2222-222222222222 \
       --incident-id REH-2024-Q4 \
       --amount 875.50 \
       --reserve-after 120.00 \
       --reason stability_rehearsal \
       --destination-account acct_test_studio_a
     ```
   - Perform one dry run, then run live against Stripe test mode.
5. **Validate outputs**
   - Confirm Stripe returns transfer ID `tr_...`.
   - Execute the generated SQL against the sandbox database.
   - Post Slack and email drafts to rehearsal channels.
6. **Settlement check**
   - Wait until transfer status shows `paid` in Stripe test balance (usually immediate).
7. **Wrap-up**
   - Re-enable the sandbox automation job.
   - Capture timestamps (start, manual transfer, finish) and compare to SLA (target < 45 minutes).
   - Note any tooling gaps or documentation updates.

Success Criteria
----------------
- Stripe transfer succeeds without manual payload edits.
- `manual_payouts` table contains rehearsal entry with correct metadata.
- Communications render correctly and contain rehearsal markers.
- Rehearsal completes within SLA; action items captured with owners.

Post-Rehearsal Actions
----------------------
- Update SOP or script if issues discovered.
- File follow-up tickets for automation hardening.
- Share summary in weekly Payments Ops meeting and archive rehearsal ticket.
