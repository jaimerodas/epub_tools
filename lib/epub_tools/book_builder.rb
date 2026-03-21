# frozen_string_literal: true

require 'fileutils'
require_relative 'loggable'
require_relative 'xhtml_extractor'
require_relative 'split_chapters'
require_relative 'add_chapters'
require_relative 'pack_ebook'
require_relative 'compile_workspace'
require_relative 'chapter_validator'

module EpubTools
  # Base class for book-building workflows (compile and append).
  # Uses template method pattern — subclasses override hooks to customize behavior.
  class BookBuilder
    include Loggable

    attr_reader :source_dir, :build_dir, :verbose

    def initialize(options = {})
      @source_dir = options.fetch(:source_dir)
      @build_dir  = options[:build_dir] || File.join(Dir.pwd, '.epub_tools_build')
      @verbose    = options[:verbose] || false
      @workspace  = CompileWorkspace.new(@build_dir)
    end

    # Run the full build workflow
    # @return [String] Path to the output EPUB file
    def run
      setup_workspace
      prepare_epub
      extract_xhtmls
      split_xhtmls
      validate_chapters
      before_add_chapters
      add_chapters
      pack_epub
      finalize_and_cleanup
    end

    private

    # Hook: called before extract/split to set up the EPUB target
    def prepare_epub; end

    # Hook: called after validation, before adding chapters
    def before_add_chapters; end

    # Subclasses must implement: the book title used when splitting chapters
    def book_title
      raise NotImplementedError, "#{self.class} must implement #book_title"
    end

    # Subclasses must implement: the output file path for pack_epub
    def output_path
      raise NotImplementedError, "#{self.class} must implement #output_path"
    end

    def setup_workspace
      @workspace.clean
      @workspace.prepare_directories
      log 'Preparing build directories...'
    end

    def extract_xhtmls
      log "Extracting XHTML files from EPUBs in '#{source_dir}'..."
      XHTMLExtractor.new(source_dir: source_dir, target_dir: @workspace.xhtml_dir, verbose: verbose).run
    end

    def split_xhtmls
      Dir.glob(File.join(@workspace.xhtml_dir, '*.xhtml')).each { |f| split_xhtml_file(f) }
    end

    def split_xhtml_file(xhtml_file)
      log "Splitting '#{File.basename(xhtml_file, '.xhtml')}'..."
      SplitChapters.new(
        input_file: xhtml_file, book_title: book_title,
        output_dir: @workspace.chapters_dir, output_prefix: 'chapter', verbose: verbose
      ).run
    end

    def validate_chapters
      ChapterValidator.new(chapters_dir: @workspace.chapters_dir, verbose: verbose).validate
    end

    def add_chapters
      log 'Adding chapters to EPUB...'
      AddChapters.new(
        chapters_dir: @workspace.chapters_dir,
        oebps_dir: epub_oebps_dir,
        verbose: verbose
      ).run
    end

    def pack_epub
      log "Building EPUB '#{output_path}'..."
      PackEbook.new(input_dir: @workspace.epub_dir, output_file: output_path, verbose: verbose).run
    end

    def finalize_and_cleanup
      log "Done. Output EPUB: #{File.expand_path(output_path)}"
      @workspace.clean
      output_path
    end

    def epub_oebps_dir = File.join(@workspace.epub_dir, 'OEBPS')
  end
end
