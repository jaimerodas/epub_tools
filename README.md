 # EPUB Tools

[![Build Status](https://github.com/jaimerodas/epub_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/jaimerodas/epub_tools/actions) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Gem Version](https://badge.fury.io/rb/epub_tools.svg)](https://badge.fury.io/rb/epub_tools)

**TL;DR:** A Ruby gem and CLI for working with EPUB files: extract, split, initialize, add chapters, pack, and unpack EPUB books.

## Installation

### Requirements
- Ruby 3.2 or higher

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
- `add`       Add chapter XHTML files into an existing EPUB
- `pack`      Package an EPUB directory into a `.epub` file
- `unpack`    Unpack a `.epub` file into a directory
- `compile`   Takes EPUBs in a dir and splits, cleans, and compiles into a single EPUB

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

# Full compile workflow: extract, split, initialize, add, and pack into one EPUB
epub-tools compile -t "My Book" -a "Author Name" -s source_epubs -c cover.jpg -o MyBook.epub
```

 (Legacy script references removed; see CLI Usage above)

## Library Usage
Use the library directly in Ruby:
```ruby
require 'epub_tools'

# Extract XHTML
EpubTools::XHTMLExtractor.new(
  source_dir: 'source_epubs',
  target_dir: 'xhtml_output',
  verbose: true
).extract_all

# Split chapters
EpubTools::SplitChapters.new(
  'xhtml_output/chapter1.xhtml',
  'My Book',
  'chapters',
  'chapter'
).run

# Initialize EPUB
EpubTools::EpubInitializer.new(
  'My Book',
  'Author Name',
  'epub_dir',
  'cover.jpg'
).run

# Add chapters
EpubTools::AddChapters.new('chapters', 'epub_dir/OEBPS').run

# Pack EPUB
EpubTools::PackEbook.new('epub_dir', 'MyBook.epub').run

# Unpack EPUB
EpubTools::UnpackEbook.new('MyBook.epub', 'unpacked_dir').run
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
