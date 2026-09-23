 # EPUB Tools

[![Build Status](https://github.com/jaimerodas/epub_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/jaimerodas/epub_tools/actions) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Gem Version](https://badge.fury.io/rb/epub_tools.svg)](https://badge.fury.io/rb/epub_tools)

**TL;DR:** A Ruby gem and CLI for working with EPUB files: extract, split, initialize, add chapters, pack, unpack, compile, and append to EPUB books.

## Installation

### Requirements
- Ruby 3.2 or higher
- [poppler](https://poppler.freedesktop.org/) (`brew install poppler`), only for PDF sources

### Install from RubyGems
```bash
gem install epub_tools
```

### Build and install locally
```bash
bundle install
gem build epub_tools.gemspec
gem install ./epub_tools-*.gem
```

## CLI Usage
After installation, use the `epub-tools` executable:

```bash
Usage: epub-tools COMMAND [options]
```

Commands:
- `init`      Initialize a new EPUB directory structure
- `extract`   Extract XHTML files from EPUB archives
- `split`     Split an XHTML file into separate chapter files
- `pdf`       Convert chapter PDFs into chapter XHTML files
- `add`       Add chapter XHTML files into an existing EPUB
- `pack`      Package an EPUB directory into a `.epub` file
- `unpack`    Unpack a `.epub` file into a directory
- `cover`     Add or replace the cover of a `.epub` file
- `compile`   Takes EPUBs and/or chapter PDFs in a dir and compiles them into a single EPUB
- `append`    Takes EPUBs and/or chapter PDFs in a dir and appends them to an existing EPUB

Run `epub-tools COMMAND --help` for details on options.

### Example
```bash
# Extract XHTMLs
epub-tools extract -s source_epubs -t xhtml_output

# Split chapters
epub-tools split -i xhtml_output/chapter1.xhtml -t "My Book" -o chapters

# Initialize EPUB
epub-tools init -t "My Book" -a "Author Name" -o epub_dir -c cover.jpg

# Add chapters to EPUB
epub-tools add -c chapters -e epub_dir/OEBPS

# Package EPUB (Ruby)
epub-tools pack -i epub_dir -o MyBook.epub

# Unpack EPUB
epub-tools unpack -i MyBook.epub -o unpacked_dir

# Add or replace the cover of an existing EPUB (keeps a MyBook.epub.bak backup)
epub-tools cover -i MyBook.epub -c cover.jpg

# Full compile workflow: extract, split, initialize, add, and pack into one EPUB
epub-tools compile -t "My Book" -a "Author Name" -s source_epubs -c cover.jpg -o MyBook.epub

# Append chapters from new EPUBs to an existing book
epub-tools append -s new_epubs -t MyBook.epub
```

### Chapter PDFs
`compile` and `append` also take a directory of chapter PDFs, one chapter per file, named
`<number><optional letters> <Title>.pdf`:

```
0 Dramatis Personae.pdf        -> "Dramatis Personae" (chapter 0 is front matter)
1 First Day.pdf                -> "Chapter 1: First Day"
1a An Interlude.pdf            -> "Chapter 1a: An Interlude", between 1 and 2
```

Paragraphs, italics, bold and scene breaks (`***`) are rebuilt from the PDF layout, and the heading typed
inside the PDF is replaced by the one from the filename. To add new chapters later, put only the new PDFs
in a directory and `append` them; chapters are slotted into reading order, even a side chapter like `12a`
added after chapter 13 is already in the book. Chapters that are already in the book are refused.

```bash
epub-tools compile -t "My Book" -a "Author Name" -s chapter_pdfs -o MyBook.epub
epub-tools append -s new_chapter_pdfs -t MyBook.epub
```

## Library Usage
Use the library directly in Ruby:
```ruby
require 'epub_tools'

# Full compile workflow: extract, split, and compile into a new EPUB
EpubTools::CompileBook.new(
  title: 'My Book', author: 'Author Name',
  source_dir: 'source_epubs', cover_image: 'cover.jpg',
  output_file: 'MyBook.epub'
).run

# Append chapters from new EPUBs to an existing book
EpubTools::AppendBook.new(
  source_dir: 'new_epubs',
  target_epub: 'MyBook.epub'
).run

# Individual steps can also be used standalone:

# Extract XHTML files from EPUBs
EpubTools::XHTMLExtractor.new(
  source_dir: 'source_epubs', target_dir: 'xhtml_output'
).run

# Split a multi-chapter XHTML into individual chapter files
EpubTools::SplitChapters.new(
  input_file: 'xhtml_output/chapter1.xhtml', book_title: 'My Book',
  output_dir: 'chapters'
).run

# Initialize a new EPUB directory structure
EpubTools::EpubInitializer.new(
  title: 'My Book', author: 'Author Name',
  destination: 'epub_dir', cover_image: 'cover.jpg'
).run

# Add chapter files into an EPUB
EpubTools::AddChapters.new(
  chapters_dir: 'chapters', oebps_dir: 'epub_dir/OEBPS'
).run

# Package an EPUB directory into a .epub file
EpubTools::PackEbook.new(input_dir: 'epub_dir', output_file: 'MyBook.epub').run

# Unpack a .epub file into a directory
EpubTools::UnpackEbook.new(epub_file: 'MyBook.epub', output_dir: 'unpacked_dir').run
```
## Development & Testing
Clone the repo and install dependencies:
```bash
git clone https://github.com/jaimerodas/epub_tools.git
cd epub_tools
bundle install
```

Run tests:
```bash
bundle exec rake test
```

Run linting (RuboCop):
```bash
bundle exec rubocop
```
## Documentation

Detailed API documentation can be generated using YARD. To view the docs locally, serve the documentation locally with YARD:

```bash
bundle exec yard server --reload
```

Then navigate to http://localhost:8808 in your browser.

To (re)generate the documentation, install the documentation dependencies and run:

```bash
bundle install --with doc
bundle exec yard doc
```

## Contributing
Pull requests welcome! Please open an issue for major changes.
