#!/usr/bin/env ruby
require 'fileutils'
require 'time'
require 'securerandom'

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
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :title Book title (required)
    # @option options [String] :author Book author (required)
    # @option options [String] :destination Target directory for the EPUB files (required)
    # @option options [String] :cover_image Optional path to the cover image
    def initialize(options = {})
      @title = options.fetch(:title)
      @author = options.fetch(:author)
      @destination = File.expand_path(options.fetch(:destination))
      @uuid = "urn:uuid:#{SecureRandom.uuid}"
      @modified = Time.now.utc.iso8601
      @cover_image_path = options[:cover_image]
      @cover_image_fname = nil
      @cover_image_media_type = nil
    end

    # Creates the empty ebook and returns the directory
    def run
      create_structure
      write_mimetype
      write_title_page
      write_container
      write_cover if @cover_image_path
      write_package_opf
      write_nav
      write_style
      @destination
    end

    private

    def create_structure
      FileUtils.mkdir_p("#{@destination}/META-INF")
      FileUtils.mkdir_p("#{@destination}/OEBPS")
    end

    def write_mimetype
      File.write("#{@destination}/mimetype", 'application/epub+zip')
    end

    def write_title_page
      content = <<~XHTML
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

      File.write("#{@destination}/OEBPS/title.xhtml", content)
    end

    def write_container
      content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/package.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
      XML
      File.write("#{@destination}/META-INF/container.xml", content)
    end

    # Copies the cover image into the EPUB structure and creates a cover.xhtml page
    def write_cover
      path = @cover_image_path
      unless File.exist?(path)
        warn "Warning: cover image '#{path}' not found; skipping cover support."
        return
      end
      ext = File.extname(path).downcase
      @cover_image_media_type = case ext
                                when '.jpg', '.jpeg' then 'image/jpeg'
                                when '.png' then 'image/png'
                                when '.gif' then 'image/gif'
                                when '.svg' then 'image/svg+xml'
                                else
                                  warn "Warning: unsupported cover image type '#{ext}'; skipping cover support."
                                  return
                                end
      @cover_image_fname = "cover#{ext}"
      dest = File.join(@destination, 'OEBPS', @cover_image_fname)
      FileUtils.cp(path, dest)
      write_cover_page
    end

    # Generates a cover.xhtml file displaying the cover image
    def write_cover_page
      content = <<~XHTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <meta charset="UTF-8" />
            <title>Cover</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <div class="cover-image">
              <img src="#{@cover_image_fname}" alt="Cover"/>
            </div>
          </body>
        </html>
      XHTML
      File.write(File.join(@destination, 'OEBPS', 'cover.xhtml'), content)
    end

    # Generates the package.opf with optional cover image entries
    def write_package_opf
      manifest_items = []
      spine_items = []

      manifest_items << '<item id="style" href="style.css" media-type="text/css"/>'
      manifest_items << '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'

      if @cover_image_fname
        manifest_items << %(<item id="cover-image" href="#{@cover_image_fname}" media-type="#{@cover_image_media_type}" properties="cover-image"/>)
        manifest_items << '<item id="cover-page" href="cover.xhtml" media-type="application/xhtml+xml"/>'
        spine_items << '<itemref idref="cover-page"/>'
      end

      manifest_items << '<item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>'
      spine_items << '<itemref idref="title"/>'

      metadata = []
      metadata << %(<dc:identifier id="pub-id">#{@uuid}</dc:identifier>)
      metadata << %(<dc:title>#{@title}</dc:title>)
      metadata << %(<dc:creator>#{@author}</dc:creator>)
      metadata << '<dc:language>en</dc:language>'
      metadata << %(<meta property="dcterms:modified">#{@modified}</meta>)
      metadata << %(<meta property="schema:accessMode">textual</meta>)
      metadata << %(<meta property="schema:accessibilityFeature">unknown</meta>)
      metadata << %(<meta property="schema:accessibilityHazard">none</meta>)
      metadata << %(<meta property="schema:accessModeSufficient">textual</meta>)
      metadata << %(<meta name="cover" content="cover-image"/>) if @cover_image_fname

      content = <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="en">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        #{metadata.map { |line| "    #{line}" }.join("\n")}
          </metadata>
          <manifest>
        #{manifest_items.map { |line| "    #{line}" }.join("\n")}
          </manifest>
          <spine>
        #{spine_items.map { |line| "    #{line}" }.join("\n")}
          </spine>
        </package>
      XML

      File.write(File.join(@destination, 'OEBPS', 'package.opf'), content)
    end

    # Generates the initial navigation document (Table of Contents)
    def write_nav
      content = <<~XHTML
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
      File.write(File.join(@destination, 'OEBPS', 'nav.xhtml'), content)
    end

    def write_style
      src = File.join(Dir.pwd, 'style.css')
      dest = File.join(@destination, 'OEBPS', 'style.css')
      unless File.exist?(src)
        warn "Warning: style.css not found in project root (#{src}), skipping copy."
        return
      end
      FileUtils.cp(src, dest)
    end
  end
end
