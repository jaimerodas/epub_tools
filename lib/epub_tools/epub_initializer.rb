#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'time'
require 'securerandom'
require_relative 'loggable'
require_relative 'xhtml_generator'
require_relative 'epub_metadata_builder'
require_relative 'epub_file_writer'

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
    # @option options [String] :cover_image Optional path to the cover image
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @title = options.fetch(:title)
      @author = options.fetch(:author)
      @destination = File.expand_path(options.fetch(:destination))
      @uuid = "urn:uuid:#{SecureRandom.uuid}"
      @modified = Time.now.utc.iso8601
      @cover_image_path = options[:cover_image]
      @cover_image_fname = nil
      @cover_image_media_type = nil
      @verbose = options[:verbose] || false
      @xhtml_generator = XhtmlGenerator.new(title: @title, author: @author)
      @metadata_builder = EpubMetadataBuilder.new(
        title: @title, 
        author: @author, 
        uuid: @uuid, 
        modified: @modified
      )
      @file_writer = EpubFileWriter.new(@destination)
    end

    # Creates the empty ebook and returns the directory
    def run
      @file_writer.create_structure
      @file_writer.write_mimetype
      write_title_page
      @file_writer.write_container
      write_cover if @cover_image_path
      write_package_opf
      write_nav
      @file_writer.write_style
      log "Created empty ebook structure at: #{@destination}"
      @destination
    end

    private

    def write_title_page
      content = @xhtml_generator.build_title_page
      @file_writer.write_xhtml('title.xhtml', content)
    end

    # Copies the cover image into the EPUB structure and creates a cover.xhtml page
    def write_cover
      return unless cover_image_exists?

      ext = File.extname(@cover_image_path).downcase
      @cover_image_media_type = determine_media_type(ext)
      return unless @cover_image_media_type

      @cover_image_fname = "cover#{ext}"
      @xhtml_generator.cover_image_fname = @cover_image_fname
      update_metadata_builder_with_cover_info
      
      copy_cover_image(ext)
      write_cover_page
    end

    def cover_image_exists?
      return true if File.exist?(@cover_image_path)

      warn "Warning: cover image '#{@cover_image_path}' not found; skipping cover support."
      false
    end

    def determine_media_type(ext)
      case ext
      when '.jpg', '.jpeg' then 'image/jpeg'
      when '.png' then 'image/png'
      when '.gif' then 'image/gif'
      when '.svg' then 'image/svg+xml'
      else
        warn "Warning: unsupported cover image type '#{ext}'; skipping cover support."
        nil
      end
    end

    def update_metadata_builder_with_cover_info
      @metadata_builder = EpubMetadataBuilder.new(
        title: @title, 
        author: @author, 
        uuid: @uuid, 
        modified: @modified,
        cover_image_fname: @cover_image_fname,
        cover_image_media_type: @cover_image_media_type
      )
    end

    def copy_cover_image(ext)
      dest = File.join(@destination, 'OEBPS', @cover_image_fname)
      FileUtils.cp(@cover_image_path, dest)
    end

    # Generates a cover.xhtml file displaying the cover image
    def write_cover_page
      content = @xhtml_generator.build_cover_page
      @file_writer.write_xhtml('cover.xhtml', content)
    end

    # Generates the package.opf with optional cover image entries
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
