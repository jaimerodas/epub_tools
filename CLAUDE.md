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
- **CLI System** (`lib/epub_tools/cli/`): Object-oriented command-line interface
  - `Runner`: Main CLI runner that handles command dispatch
  - `CommandRegistry`: Manages available commands and their configurations
  - `OptionBuilder`: Builds command-line option parsers
- **Core Classes**: Individual operation classes for EPUB manipulation
  - `XHTMLExtractor`: Extracts XHTML files from EPUB archives
  - `SplitChapters`: Splits XHTML files into separate chapters
  - `EpubInitializer`: Creates new EPUB directory structure
  - `AddChapters`: Adds chapter files to existing EPUB
  - `PackEbook`: Packages EPUB directories into .epub files
  - `UnpackEbook`: Unpacks .epub files into directories
  - `CompileBook`: Full workflow combining multiple operations

### CLI Architecture

The CLI uses a registry-based system where:
1. Commands are registered in `cli.rb` with their class, required parameters, and defaults
2. The `Runner` dispatches to the appropriate command class
3. Each command class implements a `run` method and uses the `Loggable` mixin for verbose output

### Dependencies

- **nokogiri**: XML/HTML parsing for EPUB content
- **rubyzip**: ZIP file manipulation for EPUB packaging
- **rake**: Build tasks and testing
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
- CLI tests verify command registration and option parsing
- Individual component tests verify core functionality

### Key Configuration

The RuboCop configuration disables several metrics cops (method length, class length, complexity) to accommodate the CLI option building patterns used in this codebase.