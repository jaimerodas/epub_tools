# frozen_string_literal: true

module EpubTools
  # Builds metadata content for EPUB package.opf files
  class EpubMetadataBuilder
    def initialize(title:, author:, uuid:, modified:, cover_image_fname: nil, cover_image_media_type: nil)
      @title = title
      @author = author
      @uuid = uuid
      @modified = modified
      @cover_image_fname = cover_image_fname
      @cover_image_media_type = cover_image_media_type
    end

    # Builds complete metadata array
    def build_metadata
      metadata = []
      add_dublin_core_metadata(metadata)
      add_schema_metadata(metadata)
      add_cover_metadata(metadata) if @cover_image_fname
      metadata
    end

    # Builds manifest and spine items
    def build_manifest_and_spine
      manifest_items = []
      spine_items = []

      add_base_manifest_items(manifest_items)
      add_cover_items(manifest_items, spine_items) if @cover_image_fname
      add_title_items(manifest_items, spine_items)

      [manifest_items, spine_items]
    end

    # Builds complete OPF XML content
    def build_opf_xml(metadata, manifest_items, spine_items)
      <<~XML
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
    end

    private

    def add_dublin_core_metadata(metadata)
      metadata << %(<dc:identifier id="pub-id">#{@uuid}</dc:identifier>)
      metadata << %(<dc:title>#{@title}</dc:title>)
      metadata << %(<dc:creator>#{@author}</dc:creator>)
      metadata << '<dc:language>en</dc:language>'
      metadata << %(<meta property="dcterms:modified">#{@modified}</meta>)
    end

    def add_schema_metadata(metadata)
      metadata << %(<meta property="schema:accessMode">textual</meta>)
      metadata << %(<meta property="schema:accessibilityFeature">unknown</meta>)
      metadata << %(<meta property="schema:accessibilityHazard">none</meta>)
      metadata << %(<meta property="schema:accessModeSufficient">textual</meta>)
    end

    def add_cover_metadata(metadata)
      metadata << %(<meta name="cover" content="cover-image"/>)
    end

    def add_base_manifest_items(manifest_items)
      manifest_items << mitem('style', 'style.css', 'text/css')
      manifest_items << mitem('nav', 'nav.xhtml', 'application/xhtml+xml', 'nav')
    end

    def add_cover_items(manifest_items, spine_items)
      manifest_items << mitem('cover-image', @cover_image_fname, @cover_image_media_type, 'cover-image')
      manifest_items << mitem('cover-page', 'cover.xhtml', 'application/xhtml+xml')
      spine_items << '<itemref idref="cover-page"/>'
    end

    def add_title_items(manifest_items, spine_items)
      manifest_items << mitem('title', 'title.xhtml', 'application/xhtml+xml')
      spine_items << '<itemref idref="title"/>'
    end

    def mitem(id, href, type, properties = nil)
      xml = "<item id=\"#{id}\" href=\"#{href}\" media-type=\"#{type}\""
      xml += " properties=\"#{properties}\"" if properties
      "#{xml}/>"
    end
  end
end