#!/usr/bin/env bash

set -euo pipefail

WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
destination="$WORK_DIR/_site"
baseurl=""
config=""

usage() {
  cat <<'EOF'
Usage: bash tools/build.sh [options]

Options:
  -b, --baseurl <URL>       Site-relative URL prefix.
  -d, --destination <DIR>   Output directory (default: ./_site).
      --config <PATH>       Additional Jekyll config file.
  -h, --help                Show this help.
EOF
}

copy_markdown_sources() {
  local source_root="$1"
  local output_root="$2"
  local source filename year month title target

  shopt -s nullglob
  for source in "$source_root"/_posts/*.md; do
    filename="$(basename "$source")"
    if [[ "$filename" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)\.md$ ]]; then
      year="${BASH_REMATCH[1]}"
      month="${BASH_REMATCH[2]}"
      title="${BASH_REMATCH[4]}"
      target="$output_root/$year/$month/$title/index.html.md"
      if [[ -d "$(dirname "$target")" ]]; then
        cp "$source" "$target"
      fi
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--baseurl)
      baseurl="${2:?missing base URL}"
      shift 2
      ;;
    -d|--destination)
      destination="${2:?missing destination}"
      shift 2
      ;;
    --config)
      config="${2:?missing config path}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

destination_parent="$(cd "$(dirname "$destination")" && pwd)"
destination="$destination_parent/$(basename "$destination")"
staging_root="$(mktemp -d "$destination_parent/.onev-den-build.XXXXXX")"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/onev-den-source.XXXXXX")"

cleanup() {
  rm -rf "$staging_root" "$workspace"
}
trap cleanup EXIT

rsync -a \
  --exclude '.container' \
  --exclude '_site' \
  --exclude 'vendor' \
  --exclude '.sass-cache' \
  "$WORK_DIR/" "$workspace/source/"

source_root="$workspace/source"
output_root="$staging_root/site"

(
  cd "$source_root"
  bash _scripts/sh/create_pages.sh
  bash _scripts/sh/dump_lastmod.sh

  args=(--destination "$output_root")
  [[ -n "$baseurl" ]] && args+=(--baseurl "$baseurl")
  [[ -n "$config" ]] && args+=(--config "$config")
  JEKYLL_ENV=production bundle exec jekyll build "${args[@]}"
)

copy_markdown_sources "$source_root" "$output_root"
rm -rf "$destination"
mv "$output_root" "$destination"

echo "Build succeeded: $destination"
