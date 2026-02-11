#!/usr/bin/env python3
"""RSS feed filter pipeline.

Fetches RSS feeds, applies include/exclude keyword filters,
and forwards matching items to Karakeep via its REST API.
"""

import hashlib
import json
import logging
import os
import re
import sys

import feedparser
import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s",
)
log = logging.getLogger("rss-filter")

MAX_IDS_PER_FEED = 1000


def load_config(path):
    with open(path) as f:
        return json.load(f)


def load_state(path):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {}


def save_state(state, path):
    with open(path, "w") as f:
        json.dump(state, f)


def get_item_id(entry):
    """Return a stable identifier for a feed entry."""
    if getattr(entry, "id", None):
        return entry.id
    if getattr(entry, "link", None):
        return entry.link
    raw = (getattr(entry, "title", "") + getattr(entry, "published", "")).encode()
    return hashlib.sha256(raw).hexdigest()


def get_field_text(entry, field):
    """Extract text for a given field name from a feed entry."""
    if field == "title":
        return getattr(entry, "title", "")
    if field == "description":
        return getattr(entry, "summary", "") or getattr(entry, "description", "")
    if field == "link":
        return getattr(entry, "link", "")
    if field == "any":
        parts = [
            getattr(entry, "title", ""),
            getattr(entry, "summary", "") or getattr(entry, "description", ""),
            getattr(entry, "link", ""),
        ]
        return " ".join(parts)
    return ""


def apply_filters(entry, filters):
    """Return True if the entry passes the include/exclude filters."""
    excludes = filters.get("exclude", [])
    for rule in excludes:
        text = get_field_text(entry, rule["field"])
        if text and re.search(rule["pattern"], text, re.IGNORECASE):
            return False

    includes = filters.get("include", [])
    if not includes:
        return True

    for rule in includes:
        text = get_field_text(entry, rule["field"])
        if text and re.search(rule["pattern"], text, re.IGNORECASE):
            return True

    return False


def forward_to_karakeep(entry, feed_cfg, karakeep_cfg, session):
    """Post a matching entry to Karakeep and optionally apply tags."""
    link = getattr(entry, "link", None)
    if not link:
        log.warning("Entry has no link, skipping forward: %s", getattr(entry, "title", "???"))
        return

    base = karakeep_cfg["serverAddr"].rstrip("/")

    # Create bookmark
    resp = session.post(
        f"{base}/api/v1/bookmarks",
        json={"type": "link", "url": link},
        timeout=30,
    )

    if resp.status_code == 409:
        log.info("Bookmark already exists: %s", link)
        return

    if not resp.ok:
        log.error("Failed to create bookmark for %s: %s %s", link, resp.status_code, resp.text)
        return

    bookmark = resp.json()
    bookmark_id = bookmark.get("id")
    log.info("Created bookmark %s: %s", bookmark_id, link)

    # Apply tags
    tags = feed_cfg.get("tags", [])
    if tags and bookmark_id:
        resp = session.post(
            f"{base}/api/v1/bookmarks/{bookmark_id}/tags",
            json={"tags": [{"tagName": t} for t in tags]},
            timeout=15,
        )
        if not resp.ok:
            log.warning("Failed to tag bookmark %s: %s %s", bookmark_id, resp.status_code, resp.text)


def process_feed(feed_cfg, state, karakeep_cfg, session):
    """Fetch and filter a single feed, forwarding matches."""
    url = feed_cfg["url"]
    name = feed_cfg.get("name", url)
    seen = set(state.get(url, []))

    log.info("Processing feed: %s", name)

    parsed = feedparser.parse(url)
    if parsed.bozo and not parsed.entries:
        log.error("Failed to parse feed %s: %s", name, parsed.bozo_exception)
        return

    new_count = 0
    match_count = 0

    for entry in parsed.entries:
        item_id = get_item_id(entry)
        if item_id in seen:
            continue

        seen.add(item_id)
        new_count += 1

        if apply_filters(entry, feed_cfg.get("filters", {})):
            match_count += 1
            if karakeep_cfg.get("enable", False):
                forward_to_karakeep(entry, feed_cfg, karakeep_cfg, session)

    # Cap stored IDs to prevent unbounded growth
    seen_list = list(seen)
    if len(seen_list) > MAX_IDS_PER_FEED:
        seen_list = seen_list[-MAX_IDS_PER_FEED:]
    state[url] = seen_list

    log.info("Feed %s: %d new items, %d matched filters", name, new_count, match_count)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <config.json>", file=sys.stderr)
        sys.exit(1)

    config = load_config(sys.argv[1])
    state_dir = os.environ.get("STATE_DIRECTORY", config.get("stateDir", "/var/lib/rss-filter"))
    state_path = os.path.join(state_dir, "seen.json")
    state = load_state(state_path)

    karakeep_cfg = config.get("karakeep", {})

    session = requests.Session()
    if karakeep_cfg.get("enable", False):
        api_key_file = karakeep_cfg.get("apiKeyFile", "")
        if api_key_file:
            with open(api_key_file) as f:
                api_key = f.read().strip()
            session.headers["Authorization"] = f"Bearer {api_key}"

    for feed_cfg in config.get("feeds", []):
        try:
            process_feed(feed_cfg, state, karakeep_cfg, session)
        except Exception:
            log.exception("Error processing feed %s", feed_cfg.get("name", feed_cfg.get("url", "???")))

    save_state(state, state_path)
    log.info("Done. State saved to %s", state_path)


if __name__ == "__main__":
    main()
