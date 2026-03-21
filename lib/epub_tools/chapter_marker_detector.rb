# frozen_string_literal: true

module EpubTools
  # Detects chapter boundary markers in XHTML nodes.
  # Recognizes: "Chapter N", "Chapter N (continued)", and "Prologue".
  class ChapterMarkerDetector
    # Tags that can contain chapter markers
    MARKER_TAGS = %w[p span h2 h3 h4].freeze
    # Tags that can contain prologue markers
    PROLOGUE_TAGS = %w[h3 h4].freeze

    # Detect what type of chapter marker a node represents
    # @param node [Nokogiri::XML::Node] The XHTML node to check
    # @return [Symbol, nil] :chapter, :continued, :prologue, or nil
    def detect(node)
      if continued_marker?(node)
        :continued
      elsif chapter_marker?(node)
        :chapter
      elsif prologue_marker?(node)
        :prologue
      end
    end

    # Extract the chapter number from a node's text
    # @param node [Nokogiri::XML::Node] A node containing "Chapter N" text
    # @return [Integer] The chapter number
    def extract_chapter_number(node)
      node.text.match(/Chapter\s+(\d+)/i)[1].to_i
    end

    private

    def continued_marker?(node)
      MARKER_TAGS.include?(node.name) && node.text.match?(/Chapter\s+\d+\s*\(continued\)/i)
    end

    def chapter_marker?(node)
      MARKER_TAGS.include?(node.name) && node.text.match?(/Chapter\s+\d+/i) && !continued_marker?(node)
    end

    def prologue_marker?(node)
      PROLOGUE_TAGS.include?(node.name) && node.text.strip.match?(/\APrologue\z/i)
    end
  end
end
