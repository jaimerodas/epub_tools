#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'loggable'
require_relative 'xhtml_generator'
require_relative 'epub_metadata_builder'
require_relative 'epub_file_writer'
require_relative 'epub_configuration'
require_relative 'set_cover'

module EpubTools
  # Sets up a basic empty EPUB directory structure with the basic files created:
  # - +mimetype+
  # - +container.xml+
  # - +title.xhtml+ as a title page
  # - +package.opf+
  # - +nav.xhtml+ as a table of contents
  # - +style.css+ a basic style inherited from the repo
  # - cover image (optionally)
  class EpubInitializer
    include Loggable

    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :title Book title (required)
    # @option options [String] :author Book author (required)
    # @option options [String] :destination Target directory for the EPUB files (required)
    # @option options [String] :cover_image Optional path to the cover image, added with {SetCover}[rdoc-ref:EpubTools::SetCover]
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @config = EpubConfiguration.new(options)
      @verbose = @config.verbose
      @xhtml_generator = create_xhtml_generator
      @metadata_builder = create_metadata_builder
      @file_writer = create_file_writer
    end

    private

    def create_xhtml_generator
      XhtmlGenerator.new(title: @config.title, author: @config.author)
    end

    def create_metadata_builder
      EpubMetadataBuilder.new(@config)
    end

    def create_file_writer
      EpubFileWriter.new(@config.destination)
    end

    public

    # Creates the empty ebook and returns the directory
    def run
      @file_writer.create_structure
      @file_writer.write_mimetype
      write_title_page
      @file_writer.write_container
      write_package_opf
      write_nav
      @file_writer.write_style
      write_cover if @config.cover_image_path
      log "Created empty ebook structure at: #{@config.destination}"
      @config.destination
    end

    private

    def write_title_page
      content = @xhtml_generator.build_title_page
      @file_writer.write_xhtml('title.xhtml', content)
    end

    def write_cover
      SetCover.new(cover_image: @config.cover_image_path).apply_to(File.join(@config.destination, 'OEBPS'))
    rescue ArgumentError => e
      warn "Warning: #{e.message}; skipping cover support."
    end

    # Generates the package.opf
    def write_package_opf
      manifest_items, spine_items = @metadata_builder.build_manifest_and_spine
      metadata = @metadata_builder.build_metadata
      content = @metadata_builder.build_opf_xml(metadata, manifest_items, spine_items)
      @file_writer.write_package_opf(content)
    end

    # Generates the initial navigation document (Table of Contents)
    def write_nav
      content = @xhtml_generator.build_nav_page
      @file_writer.write_xhtml('nav.xhtml', content)
    end
  end
end
