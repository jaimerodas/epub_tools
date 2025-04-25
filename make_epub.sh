#!/bin/bash

# Usage: ./make_epub.sh <epub_folder> [book.epub]
# Example: ./make_epub.sh my_epub_folder book.epub

# Exit on error
set -e

# Input directory (first arg) and output EPUB filename (optional second arg)
INPUT_DIR="$1"
# Default output to <input_dir>.epub if not provided
OUTPUT_FILE="${2:-${INPUT_DIR}.epub}"

# Usage message
USAGE="Usage: $0 <epub_folder> [output_file.epub]"

# Validate input
if [[ -z "$INPUT_DIR" ]]; then
  echo "$USAGE"
  exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: Directory '$INPUT_DIR' does not exist."
  exit 1
fi

# Ensure the mimetype is first and uncompressed
cd "$INPUT_DIR"
if [[ ! -f "mimetype" ]]; then
  echo "Error: 'mimetype' file missing in the EPUB folder."
  exit 1
fi

# Create EPUB file (uncompressed mimetype at front)
TEMP_EPUB="../$OUTPUT_FILE"
rm -f "$TEMP_EPUB"
zip -X0 "$TEMP_EPUB" mimetype
zip -Xr9D "$TEMP_EPUB" * -x mimetype

cd ..
echo "EPUB created: $OUTPUT_FILE"
