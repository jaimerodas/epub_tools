# frozen_string_literal: true

require 'nokogiri'
require 'open3'
require 'fileutils'
require_relative 'loggable'
require_relative 'pdf_layout'

module EpubTools
  # Converts chapter PDFs into chapter XHTML files that {AddChapters}[rdoc-ref:EpubTools::AddChapters] can add
  # to an EPUB. Text is read with poppler's +pdftohtml+, which keeps italics and line positions; see
  # {PDFLayout}[rdoc-ref:EpubTools::PDFLayout] for how paragraphs are rebuilt.
  #
  # PDFs must be named <tt>"<number><optional letters> <Title>.pdf"</tt>: <tt>13a I Hear You.pdf</tt> becomes
  # +chapter_13a.xhtml+, headed "Chapter 13a: I Hear You". Chapter 0 is front matter, headed with just its title.
  class PDFConverter
    include Loggable

    FILENAME = /\A(?<number>\d+)(?<suffix>[a-z]*) +(?<title>.+)\z/

    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :source_dir Directory containing the chapter PDFs (required)
    # @option options [String] :book_title Book title for the XHTML <tt><title></tt> tags (required)
    # @option options [String] :output_dir Where to write the chapter files (default: './chapters')
    # @option options [Boolean] :verbose Whether to log progress to STDOUT (default: false)
    def initialize(options = {})
      @source_dir = File.expand_path(options.fetch(:source_dir))
      @book_title = options.fetch(:book_title)
      @output_dir = File.expand_path(options[:output_dir] || './chapters')
      @verbose = options[:verbose] || false
    end

    # Runs the converter
    # @return [Array<String>] Paths of the generated chapter files (empty when there are no PDFs)
    def run
      pdfs = Dir.glob(File.join(@source_dir, '*.pdf'))
      validate_names!(pdfs)
      FileUtils.mkdir_p(@output_dir) unless pdfs.empty?
      pdfs.map { |pdf| convert(pdf) }
    end

    private

    def parse_name(pdf) = File.basename(pdf, '.pdf').unicode_normalize(:nfc).match(FILENAME)

    def validate_names!(pdfs)
      bad = pdfs.reject { |pdf| parse_name(pdf) }.map { |pdf| File.basename(pdf) }
      return if bad.empty?

      raise ArgumentError, "PDF names must look like '12a Chapter Title.pdf': #{bad.join(', ')}"
    end

    def convert(pdf)
      number, title = chapter_name(pdf)
      label = number == '0' ? title : "Chapter #{number}: #{title}"
      path = File.join(@output_dir, "chapter_#{number}.xhtml")
      File.write(path, well_formed(build_xhtml(label.encode(xml: :text), chapter_body(pdf))))
      log "Converted: #{File.basename(pdf)} -> #{File.basename(path)}"
      path
    end

    # @return [Array(String, String)] The chapter number without leading zeros (e.g. "13a") and its title
    def chapter_name(pdf)
      name = parse_name(pdf)
      ["#{name[:number].to_i}#{name[:suffix]}", name[:title].tr("'", '’')]
    end

    def chapter_body(pdf)
      layout = PDFLayout.new(pdftohtml(pdf))
      raise "No text found in '#{pdf}' (is it a scanned image?)" if layout.empty?

      layout.to_html
    end

    def pdftohtml(pdf)
      xml, status = Open3.capture2('pdftohtml', '-xml', '-i', '-q', '-stdout', pdf)
      raise "pdftohtml failed to read '#{pdf}'" unless status.success?

      Nokogiri::XML(xml)
    rescue Errno::ENOENT
      raise 'pdftohtml not found; install poppler (e.g. `brew install poppler`) to convert PDFs'
    end

    def well_formed(xhtml)
      Nokogiri::XML(xhtml, &:strict)
      xhtml
    end

    def build_xhtml(label, body)
      <<~HTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <title>#{@book_title.encode(xml: :text)} - #{label}</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <h1>#{label}</h1>
            #{body}
          </body>
        </html>
      HTML
    end
  end
end
