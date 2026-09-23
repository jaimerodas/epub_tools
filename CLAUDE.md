# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EPUB Tools is a Ruby gem and CLI for working with EPUB files. It provides functionality to extract, split, initialize, add chapters, pack, and unpack EPUB books. The project uses a modular architecture with separate classes for each operation and a structured CLI system.

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rake test

# Run a specific test file
ruby -Itest test/specific_test.rb
```

### Linting
```bash
# Run RuboCop linting
bundle exec rubocop

# Fix auto-correctable issues
bundle exec rubocop --auto-correct
```

### Dependencies
```bash
# Install dependencies
bundle install

# Install with documentation dependencies
bundle install --with doc
```

### Documentation
```bash
# Generate and serve YARD documentation
bundle exec yard server --reload
# Then visit http://localhost:8808

# Generate documentation files
bundle exec yard doc
```

### Gem Management
```bash
# Build the gem
gem build epub_tools.gemspec

# Install locally built gem
gem install ./epub_tools-*.gem
```

## Architecture

### Core Components

- **Main Module** (`lib/epub_tools.rb`): Entry point that requires all components
- **CLI** (`lib/epub_tools/cli.rb`): `CLI::COMMANDS` maps each command to its class, summary and flags
- **Core Classes**: Individual operation classes for EPUB manipulation
  - `XHTMLExtractor`: Extracts XHTML files from EPUB archives
  - `PDFConverter`: Converts chapter PDFs (named `12a Title.pdf`) into chapter XHTMLs via poppler's `pdftohtml -xml`
  - `SplitChapters`: Splits XHTML files into separate chapters at Chapter N / Chapter N (continued) / Prologue markers
  - `EpubInitializer`: Creates new EPUB directory structure
  - `AddChapters`: Adds chapter files to existing EPUB
  - `PackEbook`: Packages EPUB directories into .epub files
  - `UnpackEbook`: Unpacks .epub files into directories
  - `SetCover`: Adds or replaces a cover, in a packed EPUB (`cover` command) or an unpacked one (used by `EpubInitializer`)
- **Workflow Classes**: Orchestrators built on a shared base class
  - `BookBuilder`: Base class with template method pattern (extract → split → convert PDFs → validate → add → pack)
  - `CompileBook`: Creates a new EPUB from source EPUBs (inherits BookBuilder)
  - `AppendBook`: Appends chapters from source EPUBs to an existing EPUB (inherits BookBuilder)
- **Supporting Classes**
  - `ChapterValidator`: Validates chapter sequence completeness
  - `PDFLayout`: Rebuilds paragraphs, italics, scene breaks and lists from `pdftohtml -xml` line positions
  - `ChapterOrder`: Reading order of chapter files (1, 1_5, 1a, 1b, 2); inserts added chapters in place
  - `StyleFinder` / `XHTMLCleaner`: Find Google Docs' bold/italic classes and clean split chapters with them

### CLI Architecture

1. Each command is an entry in `CLI::COMMANDS`: its class, usage summary, and flags as `[short, long, description, option key]`
2. Flags whose description ends in `(required)` are enforced; commands get `-q/--quiet` unless marked `verbose: false`
3. `CLI.run` parses the flags and calls `command_class.new(options).run`
4. Each command class implements a `run` method and uses the `Loggable` mixin for verbose output

### Dependencies

- **nokogiri**: XML/HTML parsing for EPUB content
- **rubyzip**: ZIP file manipulation for EPUB packaging
- **rake**: Build tasks and testing (development only)
- **minitest**: Testing framework
- **rubocop**: Code linting with custom configuration
- **simplecov**: Test coverage reporting

### File Structure

- `bin/epub-tools`: Executable CLI entry point
- `lib/epub_tools/`: Main library code
- `test/`: Minitest-based test suite
- `.rubocop.yml`: RuboCop configuration with relaxed complexity rules
- `epub_tools.gemspec`: Gem specification
- `Gemfile`: Dependency management

### Testing Patterns

Tests use Minitest with:
- `test_helper.rb` sets up SimpleCov coverage
- Tests in `test/` directory follow `*_test.rb` naming
- CLI tests verify option parsing and dispatch; `cli_commands_test.rb` runs the real executable
- Individual component tests verify core functionality

### Code Quality

- One class per operation, each with an options hash and a `run` method
- Prefer plain methods, stdlib and the existing dependencies over new helper classes

RuboCop configuration excludes test files from metrics cops while maintaining strict standards for production code.