#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <Book Title> <Author> <Source EPUBs Dir> [Cover Image Path] [Output EPUB Filename]"
  exit 1
}

if [[ $# -lt 3 || $# -gt 5 ]]; then
  usage
fi

TITLE="$1"
AUTHOR="$2"
SOURCE_DIR="$3"
# Parse optional cover image and output filename
COVER_IMAGE=""
case $# in
  3)
    OUTPUT_FILE="${TITLE// /_}.epub";;
  4)
    if [[ "${4}" == *.epub ]]; then
      OUTPUT_FILE="${4}"
    else
      COVER_IMAGE="${4}"
      OUTPUT_FILE="${TITLE// /_}.epub"
    fi;;
  5)
    COVER_IMAGE="${4}"
    OUTPUT_FILE="${5}";;
  *)
    usage;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prepare build directories
BUILD_DIR="$(pwd)/build"
XHTML_DIR="$BUILD_DIR/xhtml"
CHAPTERS_DIR="$BUILD_DIR/chapters"
EPUB_DIR="$BUILD_DIR/epub"

rm -rf "$BUILD_DIR"
mkdir -p "$XHTML_DIR" "$CHAPTERS_DIR"

echo "Extracting XHTML files from epubs in '$SOURCE_DIR'..."
"$SCRIPT_DIR/bin/epub-tools" extract -s "$SOURCE_DIR" -t "$XHTML_DIR"

echo "Splitting XHTML files into chapters..."
for xhtml_file in "$XHTML_DIR"/*.xhtml; do
  base="$(basename "$xhtml_file" .xhtml)"
  echo "Splitting '$base'..."
  "$SCRIPT_DIR/bin/epub-tools" split -i "$xhtml_file" -t "$TITLE" -o "$CHAPTERS_DIR"
done

# Validate contiguous chapter numbers
echo "Validating chapter sequence..."
chapter_nums=()
for file in "$CHAPTERS_DIR"/*.xhtml; do
  fname=$(basename "$file" .xhtml)
  num="${fname##*_}"
  if [[ "$num" =~ ^[0-9]+$ ]]; then
    chapter_nums+=("$num")
  fi
done
if (( ${#chapter_nums[@]} == 0 )); then
  echo "Error: No chapter files found in $CHAPTERS_DIR"
  exit 1
fi
sorted_nums=($(printf "%s\n" "${chapter_nums[@]}" | sort -n | uniq))
min=${sorted_nums[0]}
last_index=$((${#sorted_nums[@]} - 1))
max=${sorted_nums[$last_index]}
missing=()
for ((i=min; i<=max; i++)); do
  if ! printf "%s\n" "${sorted_nums[@]}" | grep -qx "$i"; then
    missing+=("$i")
  fi
done
if (( ${#missing[@]} > 0 )); then
  echo "Error: Missing chapter numbers: ${missing[*]}"
  exit 1
else
  echo "Chapter sequence is complete: $min to $max."
fi

echo "Initializing new EPUB..."
if [[ -n "$COVER_IMAGE" ]]; then
  "$SCRIPT_DIR/bin/epub-tools" init -t "$TITLE" -a "$AUTHOR" -o "$EPUB_DIR" -c "$COVER_IMAGE"
else
  "$SCRIPT_DIR/bin/epub-tools" init -t "$TITLE" -a "$AUTHOR" -o "$EPUB_DIR"
fi

echo "Adding chapters to EPUB..."
"$SCRIPT_DIR/bin/epub-tools" add -c "$CHAPTERS_DIR" -e "$EPUB_DIR/OEBPS"

echo "Building final EPUB '$OUTPUT_FILE'..."
"$SCRIPT_DIR/bin/epub-tools" pack -i "$EPUB_DIR" -o "../$OUTPUT_FILE"

echo "Done. Output EPUB: $(pwd)/$OUTPUT_FILE"

# Cleanup build directory
rm -rf "$BUILD_DIR"
