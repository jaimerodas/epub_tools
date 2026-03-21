#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'yaml'
require 'fileutils'
require_relative 'loggable'
require_relative 'style_finder'
require_relative 'xhtml_cleaner'
require_relative 'chapter_marker_detector'

module EpubTools
  # Splits a multi-chapter XHTML file into individual chapter files.
  class SplitChapters
    include Loggable

    def initialize(options = {})
      @input_file    = options.fetch(:input_file)
      @book_title    = options.fetch(:book_title)
      @output_dir    = options[:output_dir] || './chapters'
      @output_prefix = options[:output_prefix] || 'chapter'
      @verbose       = options[:verbose] || false
      @detector      = ChapterMarkerDetector.new
    end

    # Runs the splitter
    # @return [Array<String>] List of generated chapter file paths
    def run
      FileUtils.mkdir_p(@output_dir)
      doc = Nokogiri::HTML(read_and_strip_problematic_tags)
      StyleFinder.new({ file_path: @input_file, verbose: @verbose }).run
      extract_chapters(doc).map { |number, content| write_chapter_file(number, content) }
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
      marker = @detector.detect(node)
      if marker
        start_chapter(chapters, marker_number(marker, node), current_number, current_fragment)
      else
        current_fragment&.add_child(node.dup)
        [current_number, current_fragment]
      end
    end

    def marker_number(marker, node)
      case marker
      when :continued then @detector.extract_chapter_number(node) + 0.5
      when :chapter then @detector.extract_chapter_number(node)
      when :prologue then 0
      end
    end

    def start_chapter(chapters, number, current_number, current_fragment)
      chapters[current_number] = current_fragment.to_html if current_number
      [number, Nokogiri::HTML::DocumentFragment.parse('')]
    end

    def write_chapter_file(label, content)
      display = display_label(label)
      filename = File.join(@output_dir, "#{@output_prefix}_#{file_label(label)}.xhtml")
      File.write(filename, build_xhtml_template(display, content))
      XHTMLCleaner.new({ filename: filename }).run
      log("Extracted: #{filename}")
      filename
    end

    def build_xhtml_template(display_label, content)
      <<~HTML
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
