#!/usr/bin/env ruby
require 'fileutils'
require_relative 'loggable'
require_relative 'xhtml_extractor'
require_relative 'split_chapters'
require_relative 'epub_initializer'
require_relative 'add_chapters'
require_relative 'pack_ebook'

module EpubTools
  # Orchestrates extraction, splitting, validation, and packaging of book EPUBs
  class CompileBook
    include Loggable
    # Book title
    attr_reader :title
    # Book author
    attr_reader :author
    # Path of the input epubs
    attr_reader :source_dir
    # Optional path to the cover image
    attr_reader :cover_image
    # Filename for the final epub
    attr_reader :output_file
    # Optional working directory for intermediate files
    attr_reader :build_dir
    # Whether to print progress to STDOUT
    attr_reader :verbose

    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :title Book title (required)
    # @option options [String] :author Book author (required)
    # @option options [String] :source_dir Path of the input epubs (required)
    # @option options [String] :cover_image Optional path to the cover image
    # @option options [String] :output_file Filename for the final epub (default: [title].epub)
    # @option options [String] :build_dir Optional working directory for intermediate files
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @title       = options.fetch(:title)
      @author      = options.fetch(:author)
      @source_dir  = options.fetch(:source_dir)
      @cover_image = options[:cover_image]
      @output_file = options[:output_file] || default_output_file
      @build_dir   = options[:build_dir] || File.join(Dir.pwd, '.epub_tools_build')
      @verbose     = options[:verbose] || false
    end

    # Run the full compile workflow
    def run
      clean_build_dir
      prepare_dirs
      extract_xhtmls
      split_xhtmls
      validate_sequence
      initialize_epub
      add_chapters
      pack_epub
      log "Done. Output EPUB: #{File.expand_path(output_file)}"
      clean_build_dir
    end

    private

    def default_output_file
      "#{title.gsub(' ', '_')}.epub"
    end

    def clean_build_dir
      log "Cleaning build directory #{build_dir}..."
      FileUtils.rm_rf(build_dir)
    end

    def prepare_dirs
      log 'Preparing build directories...'
      FileUtils.mkdir_p(xhtml_dir)
      FileUtils.mkdir_p(chapters_dir)
    end

    def xhtml_dir
      @xhtml_dir ||= File.join(build_dir, 'xhtml')
    end

    def chapters_dir
      @chapters_dir ||= File.join(build_dir, 'chapters')
    end

    def epub_dir
      @epub_dir ||= File.join(build_dir, 'epub')
    end

    def extract_xhtmls
      log "Extracting XHTML files from epubs in '#{source_dir}'..."
      XHTMLExtractor.new({
                           source_dir: source_dir,
                           target_dir: xhtml_dir,
                           verbose: verbose
                         }).run
    end

    def split_xhtmls
      log 'Splitting XHTML files into chapters...'
      Dir.glob(File.join(xhtml_dir, '*.xhtml')).each do |xhtml_file|
        base = File.basename(xhtml_file, '.xhtml')
        log "Splitting '#{base}'..."
        SplitChapters.new({
                            input_file: xhtml_file,
                            book_title: title,
                            output_dir: chapters_dir,
                            output_prefix: 'chapter',
                            verbose: verbose
                          }).run
      end
    end

    def validate_sequence
      log 'Validating chapter sequence...'
      nums = Dir.glob(File.join(chapters_dir, '*.xhtml')).map do |file|
        if (m = File.basename(file, '.xhtml').match(/_(\d+)\z/))
          m[1].to_i
        end
      end.compact
      raise "No chapter files found in #{chapters_dir}" if nums.empty?

      sorted = nums.sort.uniq
      missing = (sorted.first..sorted.last).to_a - sorted
      raise "Missing chapter numbers: #{missing.join(' ')}" if missing.any?

      log "Chapter sequence is complete: #{sorted.first} to #{sorted.last}."
    end

    def initialize_epub
      log 'Initializing new EPUB...'
      if cover_image
        EpubInitializer.new({
                              title: title,
                              author: author,
                              destination: epub_dir,
                              cover_image: cover_image
                            }).run
      else
        EpubInitializer.new({
                              title: title,
                              author: author,
                              destination: epub_dir
                            }).run
      end
    end

    def add_chapters
      log 'Adding chapters to EPUB...'
      AddChapters.new({
                        chapters_dir: chapters_dir,
                        epub_dir: File.join(epub_dir, 'OEBPS'),
                        verbose: verbose
                      }).run
    end

    def pack_epub
      log "Building final EPUB '#{output_file}'..."
      PackEbook.new({
                      input_dir: epub_dir,
                      output_file: output_file,
                      verbose: verbose
                    }).run
    end
  end
end
