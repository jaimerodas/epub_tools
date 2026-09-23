# frozen_string_literal: true

require 'nokogiri'
require 'fileutils'
require 'tmpdir'
require_relative 'loggable'
require_relative 'unpack_ebook'
require_relative 'pack_ebook'

module EpubTools
  # Adds a cover image to an EPUB, replacing any cover it already has: the image, a +cover.xhtml+ page first in
  # the reading order, and the manifest and metadata entries marking it as the cover.
  #
  # {#run} updates a packed +.epub+ in place (backing it up to <tt><epub>.bak</tt> first). The book keeps its
  # identifier, so reading apps still treat it as the same book. {#apply_to} updates an unpacked EPUB instead;
  # {EpubInitializer}[rdoc-ref:EpubTools::EpubInitializer] uses it for new books.
  class SetCover
    include Loggable

    # Media types of the supported cover image extensions
    MEDIA_TYPES = {
      '.jpg' => 'image/jpeg', '.jpeg' => 'image/jpeg', '.png' => 'image/png', '.gif' => 'image/gif',
      '.svg' => 'image/svg+xml'
    }.freeze

    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :cover_image Path to the cover image: jpg, png, gif or svg (required)
    # @option options [String] :epub_file The EPUB to add the cover to (required for {#run})
    # @option options [Boolean] :verbose Whether to log progress to STDOUT (default: false)
    # @raise [ArgumentError] if a file is missing or the image type is unsupported
    def initialize(options = {})
      @cover_image = File.expand_path(options.fetch(:cover_image))
      @extension = File.extname(@cover_image).downcase
      @epub_file = options[:epub_file] && File.expand_path(options[:epub_file])
      @verbose = options[:verbose] || false
      validate!
    end

    # Adds the cover to +epub_file+
    # @return [String] Path to the updated EPUB
    def run
      raise ArgumentError, 'An :epub_file is required to run' unless @epub_file

      FileUtils.cp(@epub_file, "#{@epub_file}.bak")
      Dir.mktmpdir do |dir|
        UnpackEbook.new(epub_file: @epub_file, output_dir: dir).run
        apply_to(File.join(dir, 'OEBPS'))
        PackEbook.new(input_dir: dir, output_file: @epub_file).run
      end
      log "Set the cover of #{@epub_file} to #{File.basename(@cover_image)} (backup: #{@epub_file}.bak)"
      @epub_file
    end

    # Adds the cover to an unpacked EPUB
    # @param oebps_dir [String] Directory containing the EPUB's +package.opf+
    def apply_to(oebps_dir)
      opf_path = File.join(oebps_dir, 'package.opf')
      opf = Nokogiri::XML(File.read(opf_path)) { |config| config.default_xml.noblanks }
      remove_old_cover(opf, oebps_dir)
      FileUtils.cp(@cover_image, File.join(oebps_dir, image_name))
      File.write(File.join(oebps_dir, 'cover.xhtml'), cover_page)
      add_cover(opf)
      File.write(opf_path, opf.to_xml(indent: 2))
    end

    private

    def validate!
      raise ArgumentError, "EPUB '#{@epub_file}' not found" if @epub_file && !File.file?(@epub_file)
      raise ArgumentError, "cover image '#{@cover_image}' not found" unless File.file?(@cover_image)
      return if MEDIA_TYPES.key?(@extension)

      raise ArgumentError, "unsupported cover image type '#{@extension}' (use jpg, png, gif or svg)"
    end

    def image_name = "cover#{@extension}"

    def cover_page
      <<~XHTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <meta charset="UTF-8" />
            <title>Cover</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <div class="cover-image">
              <img src="#{image_name}" alt="Cover"/>
            </div>
          </body>
        </html>
      XHTML
    end

    def remove_old_cover(opf, oebps_dir)
      opf.xpath('//xmlns:item[@id="cover-image" or contains(@properties, "cover-image")]').each do |item|
        FileUtils.rm_f(File.join(oebps_dir, item['href']))
        item.remove
      end
      opf.xpath('//xmlns:meta[@name="cover"] | //xmlns:item[@id="cover-page"] | //xmlns:itemref[@idref="cover-page"]')
         .each(&:remove)
    end

    def add_cover(opf)
      opf.at_xpath('//xmlns:metadata').add_child(opf.create_element('meta', name: 'cover', content: 'cover-image'))
      manifest = opf.at_xpath('//xmlns:manifest')
      manifest.add_child(opf.create_element('item', id: 'cover-image', href: image_name,
                                                    'media-type': MEDIA_TYPES[@extension], properties: 'cover-image'))
      manifest.add_child(opf.create_element('item', id: 'cover-page', href: 'cover.xhtml',
                                                    'media-type': 'application/xhtml+xml'))
      opf.at_xpath('//xmlns:spine').prepend_child(opf.create_element('itemref', idref: 'cover-page'))
    end
  end
end
