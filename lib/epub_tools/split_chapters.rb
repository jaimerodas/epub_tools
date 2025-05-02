#!/usr/bin/env ruby
require 'nokogiri'
require 'yaml'
require_relative 'loggable'
require_relative 'style_finder'
require_relative 'xhtml_cleaner'

module EpubTools
  # Takes a Google Docs generated, already extracted from their EPUB, XHTML files with multiple
  # chapters and it:
  # - Extracts classes using {StyleFinder}[rdoc-ref:EpubTools::StyleFinder]
  # - Looks for tags that say something like Chapter XX or Prologue and splits the text there
  # - Creates new chapter_XX.xhtml files that are cleaned using
  #   {XHTMLCleaner}[rdoc-ref:EpubTools::XHTMLCleaner]
  # - Saves those files to +output_dir+
  class SplitChapters
    include Loggable
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :input_file Path to the source XHTML (required)
    # @option options [String] :book_title Title to use in HTML <title> tags (required)
    # @option options [String] :output_dir Where to write chapter files (default: './chapters')
    # @option options [String] :output_prefix Filename prefix for chapter files (default: 'chapter')
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @input_file    = options.fetch(:input_file)
      @book_title    = options.fetch(:book_title)
      @output_dir    = options[:output_dir] || './chapters'
      @output_prefix = options[:output_prefix] || 'chapter'
      @verbose       = options[:verbose] || false
    end

    # Runs the splitter
    # @return [Array<String>] List of generated chapter file paths
    def run
      # Prepare output dir
      Dir.mkdir(@output_dir) unless Dir.exist?(@output_dir)

      # Read the doc
      raw_content = read_and_strip_problematic_tags
      doc = Nokogiri::HTML(raw_content)

      # Find Style Classes
      StyleFinder.new({ file_path: @input_file, verbose: @verbose }).run

      chapters = extract_chapters(doc)
      write_chapter_files(chapters)
    end

    private

    def read_and_strip_problematic_tags
      File.read(@input_file).gsub(%r{<hr\b[^>]*/?>}i, '').gsub(%r{<br\b[^>]*/?>}i, '')
    end

    def extract_chapters(doc)
      chapters = {}
      current_number = nil
      current_fragment = nil

      doc.at('body').children.each do |node|
        if (m = node.text.match(/Chapter\s+(\d+)/i)) && %w[p span h2 h3 h4].include?(node.name)
          # start a new chapter (skip the marker node so title isn't duplicated)
          chapters[current_number] = current_fragment.to_html if current_number
          current_number = m[1].to_i
          current_fragment = Nokogiri::HTML::DocumentFragment.parse('')
        elsif prologue_marker?(node)
          # start the prologue (skip the marker node)
          chapters[current_number] = current_fragment.to_html if current_number
          current_number = 0
          current_fragment = Nokogiri::HTML::DocumentFragment.parse('')
        else
          current_fragment&.add_child(node.dup)
        end
      end

      chapters[current_number] = current_fragment.to_html if current_number
      chapters
    end

    def write_chapter_files(chapters)
      chapter_files = []
      chapters.each do |number, content|
        filename = write_chapter_file(number, content)
        chapter_files << filename
      end
      chapter_files
    end

    def write_chapter_file(label, content)
      display_label = display_label(label)
      filename = File.join(@output_dir, "#{@output_prefix}_#{label}.xhtml")
      File.write(filename, <<~HTML)
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <title>#{@book_title} - #{display_label}</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <h1>#{display_label}</h1>
            #{content}
          </body>
        </html>
      HTML
      XHTMLCleaner.new({ filename: filename }).run
      log("Extracted: #{filename}")
      filename
    end

    def display_label(label)
      label > 0 ? "Chapter #{label}" : 'Prologue'
    end

    # Detect a bolded Prologue marker
    def prologue_marker?(node)
      return false unless %w[h3 h4].include?(node.name)
      return false unless node.text.strip =~ /\APrologue\z/i

      true
    end
  end
end
