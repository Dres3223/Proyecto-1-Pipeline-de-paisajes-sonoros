#!/usr/bin/env bash
# Downloads the file list and metadata of BirdCLEF+ 2025.
# It does not download audio: a separate script handles a controlled subset.
#
# Usage (from the project root):
#   uv run bash scripts/download_metadata.sh

set -euo pipefail

COMPETITION="birdclef-2025"
DEST_DIR="data/raw/birdclef"
FILES=("train.csv" "taxonomy.csv" "recording_location.txt")

# 1. Pre-flight checks
if ! command -v kaggle >/dev/null 2>&1; then
  echo "ERROR: 'kaggle' command not found."
  echo "Install the dependencies with: uv sync"
  echo "and run the script with:       uv run bash scripts/download_metadata.sh"
  exit 1
fi

if [ ! -f "$HOME/.kaggle/access_token" ] && [ ! -f "$HOME/.kaggle/kaggle.json" ] \
   && [ -z "${KAGGLE_API_TOKEN:-}" ] && [ -z "${KAGGLE_KEY:-}" ]; then
  echo "ERROR: Kaggle credentials not found."
  echo "Save your token in ~/.kaggle/access_token (chmod 600) or set KAGGLE_API_TOKEN."
  exit 1
fi

mkdir -p "$DEST_DIR"

# 2. Competition file list (with sizes)
echo ">> Saving the file list to $DEST_DIR/file_list.txt"
kaggle competitions files -c "$COMPETITION" > "$DEST_DIR/file_list.txt"

# 3. Metadata (skips files already downloaded, so the script can be re-run safely)
for file in "${FILES[@]}"; do
  if [ -f "$DEST_DIR/$file" ]; then
    echo ">> $file already exists, skipping"
    continue
  fi
  echo ">> Downloading $file"
  kaggle competitions download -c "$COMPETITION" -f "$file" -p "$DEST_DIR"
  if [ -f "$DEST_DIR/$file.zip" ]; then
    unzip -o -q "$DEST_DIR/$file.zip" -d "$DEST_DIR"
    rm "$DEST_DIR/$file.zip"
  fi
done

# 4. Summary
echo
echo ">> Downloaded files:"
ls -lh "$DEST_DIR"
echo
echo ">> First rows of train.csv:"
head -3 "$DEST_DIR/train.csv"
echo
echo ">> Free disk space:"
df -h "$HOME" | tail -1
