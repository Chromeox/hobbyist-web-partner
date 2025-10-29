#!/usr/bin/env python3
"""
Manual Stripe payout fallback helper.

This script assists the payments operations team with executing a manual payout
when the automated biweekly job fails. It validates request data, optionally
invokes Stripe's Transfers API, and prints ready-to-send communications plus
an INSERT statement for the `manual_payouts` audit table.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import uuid
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from textwrap import dedent
from typing import Dict, Tuple
from urllib import error, parse, request


@dataclass
class FallbackRequest:
    studio_id: str
    studio_name: str
    ledger_payout_id: str
    incident_id: str
    amount_cad: Decimal
    reserve_after_cad: Decimal | None
    reason: str
    notes: str | None
    destination_account: str
    currency: str = "cad"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Execute a manual Stripe payout fallback."
    )
    parser.add_argument("--studio-id", help="UUID of the studio to pay")
    parser.add_argument("--studio-name", help="Human-readable studio name")
    parser.add_argument("--ledger-payout-id", help="Internal payout identifier")
    parser.add_argument("--incident-id", help="Incident or ticket reference")
    parser.add_argument("--amount", type=str, help="Payout amount in CAD (e.g. 123.45)")
    parser.add_argument(
        "--reserve-after",
        type=str,
        help="Reserve balance remaining after payout (CAD, optional)",
    )
    parser.add_argument(
        "--reason",
        help="Automation failure reason (e.g. scheduler_outage, bank_reject)",
    )
    parser.add_argument("--notes", help="Optional operator notes")
    parser.add_argument(
        "--destination-account",
        help="Stripe connected account ID (e.g. acct_123)",
    )
    parser.add_argument(
        "--currency",
        default="cad",
        help="Three-letter ISO currency for the transfer (default: cad)",
    )
    parser.add_argument(
        "--request-json",
        type=str,
        help="Path to JSON export from the fallback request form",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Skip the live Stripe API call and print the payload only",
    )
    parser.add_argument(
        "--idempotency-key",
        help="Override idempotency key (defaults to ledger payout id)",
    )
    parser.add_argument(
        "--no-communications",
        action="store_true",
        help="Suppress email and Slack message output",
    )
    parser.add_argument(
        "--no-sql",
        action="store_true",
        help="Do not print the manual_payouts INSERT statement",
    )
    return parser.parse_args()


def load_request_from_json(path: Path) -> Dict[str, str]:
    with path.open("r", encoding="utf-8") as handle:
        try:
            payload = json.load(handle)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise SystemExit(f"Expected JSON object in {path}, got {type(payload)}")
    return payload


def coalesce_request(args: argparse.Namespace) -> FallbackRequest:
    request_payload: Dict[str, str] = {}
    if args.request_json:
        request_payload = load_request_from_json(Path(args.request_json))

    def pick(key: str, cli_value: str | None, required: bool = True) -> str:
        value = cli_value or request_payload.get(key)
        if required and not value:
            raise SystemExit(f"Missing required value for '{key}'.")
        return value or ""

    amount_raw = pick("amount", args.amount)
    try:
        amount_cad = Decimal(amount_raw).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    except Exception as exc:  # pylint: disable=broad-except
        raise SystemExit(f"Invalid amount '{amount_raw}': {exc}") from exc

    reserve_after = None
    reserve_raw = args.reserve_after or request_payload.get("reserve_after")
    if reserve_raw:
        try:
            reserve_after = Decimal(reserve_raw).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
        except Exception as exc:  # pylint: disable=broad-except
            raise SystemExit(f"Invalid reserve_after '{reserve_raw}': {exc}") from exc

    return FallbackRequest(
        studio_id=pick("studio_id", args.studio_id),
        studio_name=pick("studio_name", args.studio_name),
        ledger_payout_id=pick("ledger_payout_id", args.ledger_payout_id),
        incident_id=pick("incident_id", args.incident_id),
        amount_cad=amount_cad,
        reserve_after_cad=reserve_after,
        reason=pick("reason", args.reason),
        notes=args.notes or request_payload.get("notes"),
        destination_account=pick("destination_account", args.destination_account),
        currency=(args.currency or request_payload.get("currency") or "cad").lower(),
    )


def cents(amount_cad: Decimal) -> int:
    cents_value = int((amount_cad * 100).to_integral_value(rounding=ROUND_HALF_UP))
    if cents_value <= 0:
        raise SystemExit("Amount must be greater than zero.")
    return cents_value


def stripe_transfer_payload(data: FallbackRequest) -> Tuple[Dict[str, str], Dict[str, str]]:
    base_payload = {
        "amount": str(cents(data.amount_cad)),
        "currency": data.currency,
        "destination": data.destination_account,
        "description": f"Manual payout for {data.studio_name}",
    }
    metadata = {
        "manual_payout": "true",
        "incident_id": data.incident_id,
        "ledger_payout_id": data.ledger_payout_id,
        "studio_id": data.studio_id,
        "studio_name": data.studio_name,
        "reason": data.reason,
    }
    if data.reserve_after_cad is not None:
        metadata["reserve_after_cad"] = f"{data.reserve_after_cad:.2f}"
    if data.notes:
        metadata["notes"] = data.notes
    return base_payload, metadata


def call_stripe(
    form_values: Dict[str, str],
    metadata: Dict[str, str],
    idempotency_key: str,
    secret_key: str,
) -> Dict[str, object]:
    encoded: list[Tuple[str, str]] = list(form_values.items())
    for key, value in metadata.items():
        encoded.append((f"metadata[{key}]", value))

    data = parse.urlencode(encoded).encode("utf-8")
    req = request.Request("https://api.stripe.com/v1/transfers", data=data)
    token = base64.b64encode(f"{secret_key}:".encode("utf-8")).decode("ascii")
    req.add_header("Authorization", f"Basic {token}")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("User-Agent", "HobbyAppManualPayout/1.0")
    req.add_header("Idempotency-Key", idempotency_key)

    try:
        with request.urlopen(req, timeout=30) as resp:  # nosec B310
            payload = resp.read().decode("utf-8")
            return json.loads(payload)
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(
            f"Stripe API error {exc.code}: {exc.reason}\n{body}"
        ) from exc
    except error.URLError as exc:
        raise SystemExit(f"Network error when calling Stripe: {exc}") from exc


def format_slack_message(data: FallbackRequest, stripe_id: str) -> str:
    return dedent(
        f"""\
        :warning: Manual payout triggered
        • Studio: {data.studio_name} ({data.studio_id})
        • Amount: CAD {data.amount_cad:.2f}
        • Incident: {data.incident_id}
        • Reason: {data.reason}
        • Approvers: <fill before sending>
        • Stripe transfer: {stripe_id}
        """
    ).strip()


def format_email_template(data: FallbackRequest, stripe_id: str) -> str:
    return dedent(
        f"""\
        Subject: Manual payout confirmation for {data.studio_name}

        Hi {data.studio_name},

        We’re wrapping up your payout manually while we finalize an issue with the automated runs.
        CAD {data.amount_cad:.2f} will reach your bank within 1–2 business days (Stripe transfer ID: {stripe_id}).
        Your reserve and earnings history remain unchanged, and automated payouts resume with the next cycle.

        If you need anything else, reply here or reach us at support@hobbyist.com.

        Thanks for your patience,
        — Hobbyist Payments Team
        """
    ).strip()


def build_sql_insert(data: FallbackRequest, stripe_transfer_id: str) -> str:
    record_id = uuid.uuid4()
    now = datetime.now(timezone.utc).isoformat()
    notes_value = data.notes.replace("'", "''") if data.notes else None
    reserve_value = (
        f"{data.reserve_after_cad:.2f}" if data.reserve_after_cad is not None else "NULL"
    )

    sql = dedent(
        f"""\
        INSERT INTO manual_payouts (
            id,
            studio_id,
            studio_name,
            ledger_payout_id,
            stripe_transfer_id,
            amount_cad,
            reserve_after,
            incident_id,
            reason,
            requested_by,
            approved_by,
            created_at,
            executed_at,
            notes
        ) VALUES (
            '{record_id}',
            '{data.studio_id}',
            '{data.studio_name.replace("'", "''")}',
            '{data.ledger_payout_id}',
            '{stripe_transfer_id}',
            {data.amount_cad:.2f},
            {reserve_value},
            '{data.incident_id}',
            '{data.reason}',
            '<fill_requesting_user_uuid>',
            ARRAY['<approver_uuid_1>', '<approver_uuid_2>'],
            '{now}',
            '{now}',
            {f"'{notes_value}'" if notes_value else "NULL"}
        );
        """
    ).strip()
    return sql


def main() -> None:
    args = parse_args()
    request_data = coalesce_request(args)
    form_values, metadata = stripe_transfer_payload(request_data)

    idempotency_key = args.idempotency_key or request_data.ledger_payout_id
    stripe_secret = os.getenv("STRIPE_FALLBACK_SECRET_KEY")
    if not stripe_secret and not args.dry_run:
        raise SystemExit(
            "Missing STRIPE_FALLBACK_SECRET_KEY environment variable. "
            "Set it before running a live transfer."
        )

    print("Manual payout request:")
    print(json.dumps(asdict(request_data), indent=2, default=str))
    print("\nStripe transfer payload:")
    print(json.dumps({"form": form_values, "metadata": metadata}, indent=2))

    if args.dry_run:
        print("\nDry run enabled: skipping Stripe API call.")
        stripe_response = {"id": "<dry-run>"}
    else:
        print("\nCalling Stripe Transfers API…")
        stripe_response = call_stripe(
            form_values=form_values,
            metadata=metadata,
            idempotency_key=idempotency_key,
            secret_key=stripe_secret,
        )
        print("Stripe response:")
        print(json.dumps(stripe_response, indent=2))

    transfer_id = stripe_response.get("id", "<unknown>")

    if not args.no_sql:
        print("\nSQL insert (manual_payouts):")
        print(build_sql_insert(request_data, transfer_id))

    if not args.no_communications:
        print("\nSlack message:")
        print(format_slack_message(request_data, transfer_id))
        print("\nEmail template:")
        print(format_email_template(request_data, transfer_id))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("\nAborted by user.")
