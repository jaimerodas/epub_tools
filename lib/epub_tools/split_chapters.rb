# frozen_string_literal: true

require 'nokogiri'
require 'fileutils'
require_relative 'loggable'
require_relative 'style_finder'
require_relative 'xhtml_cleaner'

module EpubTools
  # Splits a multi-chapter XHTML file into individual chapter files, named +chapter_N.xhtml+. A chapter starts at
  # a "Chapter N" marker; "Chapter N (continued)" starts chapter N.5 and "Prologue" starts chapter 0.
  class SplitChapters
    include Loggable

    # Tags that can contain chapter markers
    MARKER_TAGS = %w[p span h2 h3 h4].freeze
    # Tags that can contain prologue markers
    PROLOGUE_TAGS = %w[h3 h4].freeze

    def initialize(options = {})
      @input_file    = options.fetch(:input_file)
      @book_title    = options.fetch(:book_title)
      @output_dir    = options[:output_dir] || './chapters'
      @verbose       = options[:verbose] || false
    end

    # Runs the splitter
    # @return [Array<String>] List of generated chapter file paths
    def run
      FileUtils.mkdir_p(@output_dir)
      doc = Nokogiri::HTML(read_and_strip_problematic_tags)
      classes = StyleFinder.new({ file_path: @input_file, verbose: @verbose }).run
      extract_chapters(doc).map { |number, content| write_chapter_file(number, content, classes) }
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
        current_number, current_fragment = process_node(node, chapters, current_number, current_fragment)
      end

      chapters[current_number] = current_fragment.to_html if current_number
      chapters
    end

    def process_node(node, chapters, current_number, current_fragment)
      number = marker_number(node)
      if number
        start_chapter(chapters, number, current_number, current_fragment)
      else
        current_fragment&.add_child(node.dup)
        [current_number, current_fragment]
      end
    end

    # @return [Numeric, nil] The chapter a marker node starts, or nil when the node is not a marker
    def marker_number(node)
      if MARKER_TAGS.include?(node.name) && (number = node.text[/Chapter\s+(\d+)/i, 1])
        node.text.match?(/Chapter\s+\d+\s*\(continued\)/i) ? number.to_i + 0.5 : number.to_i
      elsif PROLOGUE_TAGS.include?(node.name) && node.text.strip.match?(/\APrologue\z/i)
        0
      end
    end

    def start_chapter(chapters, number, current_number, current_fragment)
      chapters[current_number] = current_fragment.to_html if current_number
      [number, Nokogiri::HTML::DocumentFragment.parse('')]
    end

    def write_chapter_file(label, content, classes)
      display = display_label(label)
      filename = File.join(@output_dir, "chapter_#{file_label(label)}.xhtml")
      File.write(filename, build_xhtml_template(display, content))
      XHTMLCleaner.new({ filename: filename, classes: classes }).run
      log("Extracted: #{filename}")
      filename
    end

    def build_xhtml_template(display_label, content)
      <<~HTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <title>#{@book_title.encode(xml: :text)} - #{display_label}</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <h1>#{display_label}</h1>
            #{content}
          </body>
        </html>
      HTML
    end

    def file_label(label)
      label.is_a?(Float) ? label.to_s.gsub('.', '_') : label.to_s
    end

    def display_label(label)
      return 'Prologue' if label.zero?

      "Chapter #{label}"
    end
  end
end
