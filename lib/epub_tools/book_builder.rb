# frozen_string_literal: true

require 'fileutils'
require_relative 'loggable'
require_relative 'xhtml_extractor'
require_relative 'split_chapters'
require_relative 'pdf_converter'
require_relative 'add_chapters'
require_relative 'pack_ebook'
require_relative 'chapter_validator'

module EpubTools
  # Base class for book-building workflows (compile and append). Sources can be EPUBs (split into chapters)
  # and/or chapter PDFs (see {PDFConverter}[rdoc-ref:EpubTools::PDFConverter] for the naming convention).
  # Uses template method pattern — subclasses override hooks to customize behavior.
  class BookBuilder
    include Loggable

    attr_reader :source_dir, :build_dir, :verbose

    def initialize(options = {})
      @source_dir = options.fetch(:source_dir)
      @build_dir  = options[:build_dir] || File.join(Dir.pwd, '.epub_tools_build')
      @verbose    = options[:verbose] || false
    end

    # Run the full build workflow
    # @return [String] Path to the output EPUB file
    def run
      setup_workspace
      prepare_epub
      extract_xhtmls
      split_xhtmls
      convert_pdfs
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

    # Subclasses also define +book_title+ (used when splitting chapters) and +output_path+ (the EPUB to write)

    def setup_workspace
      FileUtils.rm_rf(build_dir)
      FileUtils.mkdir_p([xhtml_dir, chapters_dir])
      log 'Preparing build directories...'
    end

    def extract_xhtmls
      log "Extracting XHTML files from EPUBs in '#{source_dir}'..."
      XHTMLExtractor.new(source_dir: source_dir, target_dir: xhtml_dir, verbose: verbose).run
    end

    def split_xhtmls
      Dir.glob(File.join(xhtml_dir, '*.xhtml')).each { |f| split_xhtml_file(f) }
    end

    def split_xhtml_file(xhtml_file)
      log "Splitting '#{File.basename(xhtml_file, '.xhtml')}'..."
      SplitChapters.new(
        input_file: xhtml_file, book_title: book_title,
        output_dir: chapters_dir, verbose: verbose
      ).run
    end

    def convert_pdfs
      return if Dir.glob(File.join(source_dir, '*.pdf')).empty?

      log "Converting PDFs in '#{source_dir}'..."
      PDFConverter.new(
        source_dir: source_dir, book_title: book_title, output_dir: chapters_dir, verbose: verbose
      ).run
    end

    def validate_chapters
      ChapterValidator.new(chapters_dir: chapters_dir, verbose: verbose).validate
    end

    def add_chapters
      log 'Adding chapters to EPUB...'
      AddChapters.new(
        chapters_dir: chapters_dir,
        oebps_dir: epub_oebps_dir,
        verbose: verbose
      ).run
    end

    def pack_epub
      log "Building EPUB '#{output_path}'..."
      # Expanded here: PackEbook puts a relative path next to epub_dir, inside the build dir that gets deleted
      PackEbook.new(input_dir: epub_dir, output_file: File.expand_path(output_path), verbose: verbose).run
    end

    def finalize_and_cleanup
      log "Done. Output EPUB: #{File.expand_path(output_path)}"
      FileUtils.rm_rf(build_dir)
      output_path
    end

    def xhtml_dir = File.join(build_dir, 'xhtml')
    def chapters_dir = File.join(build_dir, 'chapters')
    def epub_dir = File.join(build_dir, 'epub')
    def epub_oebps_dir = File.join(epub_dir, 'OEBPS')
  end
end
