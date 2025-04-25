#!/bin/bash

# Usage: ./make_epub.sh folder_name [default.epub]
# Example: ./make_epub.sh my_epub_folder book.epub

set -e

INPUT_DIR="combined_epub"
OUTPUT_FILE="dm-and-the-dirty-20s.epub"

if [[ -z "$INPUT_DIR" ]]; then
  echo "Usage: $0 <epub_folder> [dm-and-the-dirty-20s.epub]"
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

# Create EPUB file
TEMP_EPUB="../$OUTPUT_FILE"
rm -f "$TEMP_EPUB"
zip -X0 "$TEMP_EPUB" mimetype
zip -Xr9D "$TEMP_EPUB" * -x mimetype

cd ..

echo "EPUB created: $OUTPUT_FILE"
