#!/usr/bin/env bash

set -euo pipefail

DEST="${1:-_site}"
URL_IGNORE="cdn.jsdelivr.net"

if [[ ! -d "$DEST" ]]; then
  echo "Output directory does not exist: $DEST" >&2
  exit 1
fi

for path in index.html 404.html feed.xml robots.txt sitemap.xml; do
  if [[ ! -f "$DEST/$path" ]]; then
    echo "Required output is missing: $path" >&2
    exit 1
  fi
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$script_dir/verify-edgeone-config.py" "$DEST"

for path in Brewfile.lock.json config.codekit3; do
  if [[ -e "$DEST/$path" ]]; then
    echo "Development artifact was published: $path" >&2
    exit 1
  fi
done

# Full link auditing has a large legacy baseline. Keep release validation focused
# on generated output and local image availability.
bundle exec htmlproofer "$DEST" \
  --checks=Images \
  --disable-external=true \
  --ignore-empty-alt=true \
  --ignore-missing-alt=true \
  --ignore-urls "$URL_IGNORE"
