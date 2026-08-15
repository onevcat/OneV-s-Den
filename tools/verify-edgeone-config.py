#!/usr/bin/env python3
"""Validate EdgeOne redirect rules required by the legacy nginx configuration."""

import json
import sys
from pathlib import Path

EXPECTED_REDIRECTS = {
    ("$wwwhost", "$host", 301),
    ("/feed", "/feed.xml", 301),
    ("/feed/", "/feed.xml", 301),
    ("/atom.xml", "/feed.xml", 301),
    ("/rss", "/feed.xml", 301),
    ("/rss/", "/feed.xml", 301),
    ("/myapp.json", "http://img.onevcat.com/myapp.json", 301),
}


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    root = Path(sys.argv[1]) if len(sys.argv) == 2 else Path("_site")
    config_path = root / "edgeone.json"

    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {config_path}")
    except json.JSONDecodeError as error:
        fail(f"invalid JSON in {config_path}: {error}")

    redirects = {
        (rule.get("source"), rule.get("destination"), rule.get("statusCode"))
        for rule in config.get("redirects", [])
    }
    missing = EXPECTED_REDIRECTS - redirects
    if missing:
        fail(f"missing redirect rules: {sorted(missing)}")

    print("EdgeOne redirect contract is valid")


if __name__ == "__main__":
    main()
