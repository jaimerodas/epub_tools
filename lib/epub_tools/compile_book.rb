#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require_relative 'loggable'
require_relative 'xhtml_extractor'
require_relative 'split_chapters'
require_relative 'epub_initializer'
require_relative 'add_chapters'
require_relative 'pack_ebook'
require_relative 'compile_workspace'
require_relative 'chapter_validator'

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
      @workspace   = CompileWorkspace.new(@build_dir)
    end

    # Run the full compile workflow
    def run
      setup_workspace
      extract_xhtmls
      split_xhtmls
      validate_chapters
      initialize_epub
      add_chapters
      pack_epub
      finalize_and_cleanup
    end

    private

    def setup_workspace
      @workspace.clean
      log "Cleaning build directory #{@build_dir}..."
      @workspace.prepare_directories
      log 'Preparing build directories...'
    end

    def finalize_and_cleanup
      log "Done. Output EPUB: #{File.expand_path(output_file)}"
      @workspace.clean
      output_file
    end

    def default_output_file
      "#{title.gsub(' ', '_')}.epub"
    end

    def extract_xhtmls
      log "Extracting XHTML files from epubs in '#{source_dir}'..."
      XHTMLExtractor.new({
                           source_dir: source_dir,
                           target_dir: @workspace.xhtml_dir,
                           verbose: verbose
                         }).run
    end

    def split_xhtmls
      log 'Splitting XHTML files into chapters...'
      Dir.glob(File.join(@workspace.xhtml_dir, '*.xhtml')).each do |xhtml_file|
        split_xhtml_file(xhtml_file)
      end
    end

    def split_xhtml_file(xhtml_file)
      base = File.basename(xhtml_file, '.xhtml')
      log "Splitting '#{base}'..."
      SplitChapters.new(build_split_options(xhtml_file)).run
    end

    def build_split_options(xhtml_file)
      {
        input_file: xhtml_file,
        book_title: title,
        output_dir: @workspace.chapters_dir,
        output_prefix: 'chapter',
        verbose: verbose
      }
    end

    def validate_chapters
      ChapterValidator.new(chapters_dir: @workspace.chapters_dir, verbose: verbose).validate
    end

    def initialize_epub
      log 'Initializing new EPUB...'
      EpubInitializer.new(build_epub_options).run
    end

    def build_epub_options
      options = { title: title, author: author, destination: @workspace.epub_dir }
      options[:cover_image] = cover_image if cover_image
      options
    end

    def add_chapters
      log 'Adding chapters to EPUB...'
      AddChapters.new({
                        chapters_dir: @workspace.chapters_dir,
                        epub_dir: File.join(@workspace.epub_dir, 'OEBPS'),
                        verbose: verbose
                      }).run
    end

    def pack_epub
      log "Building final EPUB '#{output_file}'..."
      PackEbook.new({
                      input_dir: @workspace.epub_dir,
                      output_file: output_file,
                      verbose: verbose
                    }).run
    end
  end
end
