#!/usr/bin/env python3
"""AWS HUB -> OneSignal web-push dispatcher.

This script is designed for GitHub Actions. It never contains the OneSignal API
key; the key must be supplied through ONESIGNAL_REST_API_KEY.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid

APP_ID = "e9e26912-3ff7-4fac-92e6-ec24f88922a4"
ONESIGNAL_URL = "https://api.onesignal.com/notifications"
APP_URL = "https://emils18.github.io/mobileSched/"
SUPABASE_URL = "https://kigculljqtosfwldzgch.supabase.co"
SUPABASE_KEY = "sb_publishable_YVTSzNoD11FYvW_O6L11cg_0g0v9WgN"

MANILA = dt.timezone(dt.timedelta(hours=8))

MONTH_ALIASES = {
    "1": 1, "01": 1, "jan": 1, "january": 1,
    "2": 2, "02": 2, "feb": 2, "february": 2,
    "3": 3, "03": 3, "mar": 3, "march": 3,
    "4": 4, "04": 4, "apr": 4, "april": 4,
    "5": 5, "05": 5, "may": 5,
    "6": 6, "06": 6, "jun": 6, "june": 6,
    "7": 7, "07": 7, "jul": 7, "july": 7,
    "8": 8, "08": 8, "aug": 8, "august": 8,
    "9": 9, "09": 9, "sep": 9, "sept": 9, "september": 9,
    "10": 10, "oct": 10, "october": 10,
    "11": 11, "nov": 11, "november": 11,
    "12": 12, "dec": 12, "december": 12,
}

MONTH_NAMES = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]


def _idempotency_key(value: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"aws-hub:{value}"))


def _request_json(url: str, *, headers: dict[str, str]) -> object:
    request = urllib.request.Request(url, headers=headers, method="GET")
    with urllib.request.urlopen(request, timeout=25) as response:
        return json.loads(response.read().decode("utf-8"))


def _supabase_rows(table: str, query: str = "") -> list[dict]:
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    if query:
        url += "?" + query

    data = _request_json(
        url,
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Accept": "application/json",
        },
    )

    return data if isinstance(data, list) else []


def _send_push(
    *,
    key: str,
    title: str,
    body: str,
    event_key: str,
    filters: list[dict] | None = None,
    included_segments: list[str] | None = None,
    data: dict | None = None,
) -> None:
    payload = {
        "app_id": APP_ID,
        "target_channel": "push",
        "name": f"AWS HUB - {event_key}",
        "headings": {"en": title},
        "contents": {"en": body},
        "url": APP_URL,
        "idempotency_key": _idempotency_key(event_key),
        "data": data or {},
    }

    if filters:
        payload["filters"] = filters

    if included_segments:
        payload["included_segments"] = included_segments

    request = urllib.request.Request(
        ONESIGNAL_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Key {key}",
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            result = response.read().decode("utf-8")
            print(f"OneSignal {event_key}: {response.status} {result}")
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        print(
            f"OneSignal {event_key} failed: HTTP {error.code}: {detail}",
            file=sys.stderr,
        )
        raise


def _and_filters(*filters: dict) -> list[dict]:
    result: list[dict] = []

    for index, item in enumerate(filters):
        if index:
            result.append({"operator": "AND"})
        result.append(item)

    return result


def send_duty_reminders(key: str, now: dt.datetime) -> None:
    # GitHub cron runs every five minutes. Normalize to the current five-minute
    # bucket and cover all five possible Time In minutes 15-19 minutes ahead.
    bucket = now.replace(
        minute=(now.minute // 5) * 5,
        second=0,
        microsecond=0,
    )

    for offset in range(15, 20):
        target = bucket + dt.timedelta(minutes=offset)
        weekday = target.weekday() + 1
        target_time = target.strftime("%H:%M")
        date_key = target.strftime("%Y-%m-%d")

        slot_value = f"{weekday}@{target_time}"
        filters = []

        for slot in range(1, 7):
            if filters:
                filters.append({"operator": "OR"})

            filters.append(
                {
                    "field": "tag",
                    "key": f"duty_slot_{slot}",
                    "relation": "=",
                    "value": slot_value,
                }
            )

        _send_push(
            key=key,
            title="Almost Time In",
            body="Your duty starts in 15 minutes. Prepare to clock in.",
            filters=filters,
            event_key=f"duty-15:{date_key}:{target_time}",
            data={"type": "duty-15", "time_in": target_time},
        )


def send_recent_announcements(key: str, now: dt.datetime) -> None:
    # Look back one hour so delayed workflow runs still catch announcements.
    # OneSignal idempotency prevents the same announcement from being delivered
    # again during repeated checks.
    since = (now - dt.timedelta(hours=1)).astimezone(dt.timezone.utc)
    since_iso = since.isoformat().replace("+00:00", "Z")

    query = urllib.parse.urlencode(
        {
            "select": "id,title,summary,body,published_at",
            "published_at": f"gte.{since_iso}",
            "order": "published_at.asc",
        },
        safe=".,:-+",
    )

    for row in _supabase_rows("announcements", query):
        announcement_id = str(row.get("id") or "").strip()
        title = str(row.get("title") or "AWS HUB Announcement").strip()
        summary = str(row.get("summary") or "").strip()
        body = str(row.get("body") or "").strip()

        if not announcement_id:
            continue

        message = summary or body or "A new AWS HUB announcement is available."
        message = message[:220]

        _send_push(
            key=key,
            title=title[:80],
            body=message,
            included_segments=["Subscribed Users"],
            event_key=f"announcement:{announcement_id}",
            data={"type": "announcement", "id": announcement_id},
        )


def _month_number(value: object) -> int:
    return MONTH_ALIASES.get(str(value or "").strip().lower(), 0)


def send_monthly_birthdays(key: str, now: dt.datetime) -> None:
    # Keep the monthly idempotency key safely inside OneSignal's 30-day window.
    if now.day > 28:
        return

    rows = _supabase_rows(
        "celebrations",
        "select=id,name,month,department&order=name.asc",
    )

    names = [
        str(row.get("name") or "").strip()
        for row in rows
        if _month_number(row.get("month")) == now.month
        and str(row.get("name") or "").strip()
    ]

    if not names:
        return

    month_name = MONTH_NAMES[now.month - 1]

    if len(names) == 1:
        body = (
            f"{names[0]} is celebrating this {month_name}. "
            "Open AWS HUB and send some birthday cheer! 🎂"
        )
    elif len(names) == 2:
        body = (
            f"{names[0]} and {names[1]} are celebrating this {month_name}. "
            "Open AWS HUB to see the celebrants! 🎉"
        )
    else:
        body = (
            f"{names[0]} and {len(names) - 1} other working scholars are "
            f"celebrating this {month_name}. Open AWS HUB to see them! 🎉"
        )

    _send_push(
        key=key,
        title=f"🎉 {month_name} Birthday Celebrants",
        body=body,
        included_segments=["Subscribed Users"],
        event_key=f"birthday-month:{now.year}-{now.month:02d}",
        data={"type": "birthday-month", "month": now.month},
    )


def main() -> int:
    key = os.environ.get("ONESIGNAL_REST_API_KEY", "").strip()

    if not key:
        print(
            "ONESIGNAL_REST_API_KEY is not configured; dispatcher skipped."
        )
        return 0

    now = dt.datetime.now(MANILA)

    send_duty_reminders(key, now)
    send_recent_announcements(key, now)
    send_monthly_birthdays(key, now)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
