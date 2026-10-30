#!/usr/bin/env bash
# Kaggle returns the competition file list in pages. This script walks through
# every page and saves:
#   - file_list_full.txt        : every file (name and size in bytes)
#   - soundscapes_available.txt : only the files under train_soundscapes/
#
# Usage (from the project root):
#   uv run bash scripts/list_files.sh

set -euo pipefail

COMPETITION="birdclef-2025"
DEST_DIR="data/raw/birdclef"
PAGE_SIZE="${PAGE_SIZE:-200}"

FULL_LIST="$DEST_DIR/file_list_full.txt"
SOUNDSCAPES="$DEST_DIR/soundscapes_available.txt"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

mkdir -p "$DEST_DIR"
: > "$FULL_LIST"

token=""
page=1
while : ; do
  if [ -z "$token" ]; then
    kaggle competitions files -c "$COMPETITION" --page-size "$PAGE_SIZE" > "$TMP"
  else
    kaggle competitions files -c "$COMPETITION" --page-size "$PAGE_SIZE" --page-token "$token" > "$TMP"
  fi

  # File rows: the first column is a path and the second one a number
  awk '$2 ~ /^[0-9]+$/ && $1 ~ /\./ {print $1, $2}' "$TMP" >> "$FULL_LIST"

  token="$(sed -n 's/^Next Page Token = //p' "$TMP")"
  printf '\r>> Page %d read (%d files so far)' "$page" "$(wc -l < "$FULL_LIST")"
  [ -z "$token" ] && break
  page=$((page + 1))
done
echo

grep '^train_soundscapes/' "$FULL_LIST" > "$SOUNDSCAPES" || true

n=$(wc -l < "$SOUNDSCAPES" | tr -d ' ')
bytes=$(awk '{s += $2} END {print s + 0}' "$SOUNDSCAPES")
echo ">> Total files:            $(wc -l < "$FULL_LIST" | tr -d ' ')"
echo ">> Soundscapes:            $n"
echo ">> Total soundscape size:  $(awk -v b="$bytes" 'BEGIN {printf "%.2f GB", b / 1e9}')"
echo ">> Examples:"
head -5 "$SOUNDSCAPES"
