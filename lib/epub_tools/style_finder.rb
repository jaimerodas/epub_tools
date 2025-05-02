#!/usr/bin/env ruby
require 'nokogiri'
require 'yaml'
require_relative 'loggable'

module EpubTools
  # Finds css classes for bold and italic texts in Google Docs-generated EPUBs. Used by
  # {XHTMLCleaner}[rdoc-ref:EpubTools::XHTMLCleaner] and
  # {SplitChapters}[rdoc-ref:EpubTools::SplitChapters].
  class StyleFinder
    include Loggable
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :file_path XHTML file to be analyzed (required)
    # @option options [String] :output_path Path to write the YAML file (default: 'text_style_classes.yaml')
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @file_path = options.fetch(:file_path)
      @output_path = options[:output_path] || 'text_style_classes.yaml'
      @verbose = options[:verbose] || false
      raise ArgumentError, "File does not exist: #{@file_path}" unless File.exist?(@file_path)
    end

    # Runs the finder
    # @return [Hash] Data containing the extracted style classes (italics and bolds)
    def run
      doc = Nokogiri::HTML(File.read(@file_path))
      style_blocks = doc.xpath('//style').map(&:text).join("\n")

      italics = extract_classes(style_blocks, /font-style\s*:\s*italic/)
      bolds   = extract_classes(style_blocks, /font-weight\s*:\s*700/)

      print_summary(italics, bolds) if @verbose

      data = {
        'italics' => italics,
        'bolds' => bolds
      }
      File.write(@output_path, data.to_yaml)
      data
    end

    private

    def extract_classes(style_text, pattern)
      regex = /\.([\w-]+)\s*{[^}]*#{pattern.source}[^}]*}/i
      style_text.scan(regex).flatten.uniq
    end

    def print_summary(italics, bolds)
      log "Classes with font-style: italic: #{italics.join(', ')}" unless italics.empty?

      return if bolds.empty?

      log "Classes with font-weight: 700: #{bolds.join(', ')}"
    end
  end
end
