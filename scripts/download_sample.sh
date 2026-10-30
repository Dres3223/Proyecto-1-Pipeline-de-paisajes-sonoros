#!/usr/bin/env bash
# Downloads the fixed soundscape sample used for local development.
# The list of recordings lives in scripts/dev_sample.txt (16 files, ~8 MB).
#
# Usage (from the project root):
#   uv run bash scripts/download_sample.sh

set -euo pipefail

COMPETITION="birdclef-2025"
LIST_FILE="scripts/dev_sample.txt"
DEST_DIR="data/raw/birdclef/train_soundscapes"

# 1. Pre-flight checks
if ! command -v kaggle >/dev/null 2>&1; then
  echo "ERROR: 'kaggle' command not found."
  echo "Install the dependencies with: uv sync"
  echo "and run the script with:       uv run bash scripts/download_sample.sh"
  exit 1
fi

if [ ! -f "$LIST_FILE" ]; then
  echo "ERROR: list file $LIST_FILE not found"
  exit 1
fi

mkdir -p "$DEST_DIR"

# 2. Download (skips files already present, so the script can be re-run safely)
downloaded=0
skipped=0
while read -r file; do
  case "$file" in ''|\#*) continue ;; esac

  if [ -f "$DEST_DIR/$file" ]; then
    skipped=$((skipped + 1))
    continue
  fi
  echo ">> Downloading $file"
  # Kaggle keeps the file's subfolder, so we download into the parent folder
  kaggle competitions download -c "$COMPETITION" -f "train_soundscapes/$file" -p "$(dirname "$DEST_DIR")" -q
  if [ -f "$DEST_DIR/$file.zip" ]; then
    unzip -o -q "$DEST_DIR/$file.zip" -d "$DEST_DIR"
    rm "$DEST_DIR/$file.zip"
  fi
  downloaded=$((downloaded + 1))
done < "$LIST_FILE"

# 3. Summary
echo
echo ">> Downloaded: $downloaded | Already present: $skipped"
echo ">> Recordings in $DEST_DIR: $(find "$DEST_DIR" -name '*.ogg' | wc -l | tr -d ' ') ($(du -sh "$DEST_DIR" | cut -f1))"
