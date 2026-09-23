# frozen_string_literal: true

require 'nokogiri'
require_relative 'loggable'

module EpubTools
  # Finds css classes for bold and italic texts in Google Docs-generated EPUBs. Used by
  # {SplitChapters}[rdoc-ref:EpubTools::SplitChapters] to tell {XHTMLCleaner}[rdoc-ref:EpubTools::XHTMLCleaner]
  # which spans are bold or italic.
  class StyleFinder
    include Loggable

    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :file_path XHTML file to be analyzed (required)
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @file_path = options.fetch(:file_path)
      @verbose = options[:verbose] || false
      raise ArgumentError, "File does not exist: #{@file_path}" unless File.exist?(@file_path)
    end

    # Runs the finder
    # @return [Hash{Symbol => Array<String>}] The +:italics+ and +:bolds+ class names
    def run
      styles = Nokogiri::HTML(File.read(@file_path)).xpath('//style').map(&:text).join("\n")
      italics = classes_with(styles, /font-style\s*:\s*italic/)
      bolds = classes_with(styles, /font-weight\s*:\s*700/)
      log "Classes with font-style: italic: #{italics.join(', ')}" unless italics.empty?
      log "Classes with font-weight: 700: #{bolds.join(', ')}" unless bolds.empty?
      { italics: italics, bolds: bolds }
    end

    private

    def classes_with(styles, pattern)
      styles.scan(/\.([\w-]+)\s*{[^}]*#{pattern.source}[^}]*}/i).flatten.uniq
    end
  end
end
