# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'time'
require_relative 'loggable'
require_relative 'set_cover'

module EpubTools
  # Sets up a basic empty EPUB directory structure with the basic files created:
  # - +mimetype+
  # - +container.xml+
  # - +title.xhtml+ as a title page
  # - +package.opf+
  # - +nav.xhtml+ as a table of contents
  # - +style.css+ the basic stylesheet that ships with the gem
  # - cover image (optionally)
  class EpubInitializer
    include Loggable

    STYLE = File.expand_path('../../style.css', __dir__)

    CONTAINER = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles>
          <rootfile full-path="OEBPS/package.opf" media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    XML

    NAV = <<~XHTML
      <?xml version="1.0" encoding="utf-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
        <head>
          <title>Table of Contents</title>
        </head>
        <body>
          <nav epub:type="toc" id="toc">
            <h1>Table of Contents</h1>
            <ol>
              <li><a href="title.xhtml">Title Page</a></li>
            </ol>
          </nav>
        </body>
      </html>
    XHTML

    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :title Book title (required)
    # @option options [String] :author Book author (required)
    # @option options [String] :destination Target directory for the EPUB files (required)
    # @option options [String] :cover_image Optional path to the cover image, added with {SetCover}[rdoc-ref:EpubTools::SetCover]
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      # Escaped once here, since they are only used inside the XML templates
      @title = options.fetch(:title).encode(xml: :text)
      @author = options.fetch(:author).encode(xml: :text)
      @destination = File.expand_path(options.fetch(:destination))
      @cover_image = options[:cover_image]
      @verbose = options[:verbose] || false
    end

    # Creates the empty ebook and returns the directory
    def run
      FileUtils.mkdir_p([File.join(@destination, 'META-INF'), oebps_dir])
      files.each { |path, content| File.write(File.join(@destination, path), content) }
      write_cover if @cover_image
      log "Created empty ebook structure at: #{@destination}"
      @destination
    end

    private

    def oebps_dir = File.join(@destination, 'OEBPS')

    def files
      { 'mimetype' => 'application/epub+zip', 'META-INF/container.xml' => CONTAINER,
        'OEBPS/title.xhtml' => title_page, 'OEBPS/package.opf' => package_opf, 'OEBPS/nav.xhtml' => NAV,
        'OEBPS/style.css' => File.read(STYLE) }
    end

    def write_cover
      SetCover.new(cover_image: @cover_image).apply_to(oebps_dir)
    rescue ArgumentError => e
      warn "Warning: #{e.message}; skipping cover support."
    end

    def title_page
      <<~XHTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <meta charset="UTF-8" />
            <title>#{@title}</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <h1 class="title">#{@title}</h1>
            <p class="author">by #{@author}</p>
          </body>
        </html>
      XHTML
    end

    def package_opf
      <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="en">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:identifier id="pub-id">urn:uuid:#{SecureRandom.uuid}</dc:identifier>
            <dc:title>#{@title}</dc:title>
            <dc:creator>#{@author}</dc:creator>
            <dc:language>en</dc:language>
            <meta property="dcterms:modified">#{Time.now.utc.iso8601}</meta>
            <meta property="schema:accessMode">textual</meta>
            <meta property="schema:accessibilityFeature">unknown</meta>
            <meta property="schema:accessibilityHazard">none</meta>
            <meta property="schema:accessModeSufficient">textual</meta>
          </metadata>
          <manifest>
            <item id="style" href="style.css" media-type="text/css"/>
            <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
            <item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>
          </manifest>
          <spine>
            <itemref idref="title"/>
          </spine>
        </package>
      XML
    end
  end
end
