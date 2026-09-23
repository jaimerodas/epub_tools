# frozen_string_literal: true

require 'nokogiri'

module EpubTools
  # Rebuilds a chapter's paragraphs from +pdftohtml -xml+ output as XHTML body markup. Used by
  # {PDFConverter}[rdoc-ref:EpubTools::PDFConverter].
  #
  # - The PDF's own title (lines larger than body text at the top of page 1) is dropped.
  # - Paragraphs are rebuilt from first-line indents and vertical gaps, including across page breaks.
  # - Lines made only of symbols (<tt>***</tt>, <tt>____</tt>) become scene breaks (<tt><hr/></tt>).
  # - Lines starting with a bullet become list items.
  # - Italics and bold are kept; ligatures (<tt>ﬁ</tt>, <tt>ﬂ</tt>) become plain letters.
  class PDFLayout
    SCENE_BREAK = /\A[*_#~=\s]+\z/
    BULLET = '•'
    RAW_XML = Nokogiri::XML::Node::SaveOptions::AS_XML
    # One line of text: the pdftohtml <text> chunks sharing a +top+ (it splits lines wherever the font changes)
    Line = Struct.new(:page, :chunks, :font_size) do
      def top = chunks.first['top'].to_i
      def left = chunks.first['left'].to_i
      def right = chunks.last['left'].to_i + chunks.last['width'].to_i
      def text = chunks.map(&:text).join
      def html = chunks.map { |chunk| chunk.children.to_xml(save_with: RAW_XML, encoding: 'UTF-8') }.join
    end

    # @param doc [Nokogiri::XML::Document] Output of <tt>pdftohtml -xml</tt>
    def initialize(doc)
      @lines = without_title(parse_lines(doc))
      @margin = @lines.map(&:left).min
      @text_edge = @lines.map(&:right).sort[@lines.size * 9 / 10]
    end

    # @return [Boolean] Whether the PDF has no body text
    def empty? = @lines.empty?

    # @return [String] XHTML for the chapter body
    def to_html
      paragraphs.chunk_while { |a, b| bullet?(a) && bullet?(b) }.map { |group| render(group) }.join("\n    ")
    end

    private

    def parse_lines(doc)
      sizes = doc.css('fontspec').to_h { |font| [font['id'], font['size'].to_i] }
      doc.css('page').flat_map { |page| page_lines(page, sizes) }
    end

    def page_lines(page, sizes)
      page.css('text').group_by { |chunk| chunk['top'].to_i }.sort.filter_map do |_top, chunks|
        chunks = visible_in_order(chunks)
        Line.new(page['number'].to_i, chunks, chunks.map { |chunk| sizes[chunk['font']] }.max) unless chunks.empty?
      end
    end

    # A line's chunks left to right, minus leading whitespace-only ones
    def visible_in_order(chunks)
      chunks.sort_by { |chunk| chunk['left'].to_i }.drop_while { |chunk| chunk.text.strip.empty? }
    end

    def without_title(lines)
      body_size = lines.map(&:font_size).tally.max_by(&:last)&.first
      lines.drop_while { |line| line.page == 1 && line.font_size > body_size * 1.4 }
    end

    # @return [Array<Array<Line>, :break>] Lines grouped into paragraphs, with scene breaks as +:break+
    def paragraphs
      @lines.each_with_object([]) do |line, paras|
        if line.text.match?(SCENE_BREAK)
          paras << :break
        elsif paras.last.is_a?(Array) && continues?(paras.last, line)
          paras.last << line
        else
          paras << [line]
        end
      end
    end

    # Distances are relative to font size: lines are ~1.2-1.45x the size apart, paragraphs ~1.9x or more.
    def continues?(para, line)
      return false if line.text.start_with?(BULLET)
      return line.left > para.first.left if bullet?(para) # wrapped bullet lines hang past the bullet
      return true if line.text.match?(/\A\p{Ll}/) # a stray paragraph break mid-sentence
      return false if line.left > @margin + 5 # first-line indent

      flows_on?(para.last, line)
    end

    # Across a page break, only a full previous line means the paragraph carries on (text is ragged-right).
    # ponytail: misses paragraph ends whose last line is nearly full width, unless the next one is indented
    def flows_on?(prev, line)
      return prev.right > @text_edge - (prev.font_size * 6) if line.page != prev.page

      line.top - prev.top < prev.font_size * 1.7
    end

    def bullet?(para) = para.is_a?(Array) && para.first.text.start_with?(BULLET)

    def render(group)
      return '<hr/>' if group.first == :break
      return "<p>#{inline_html(group.first)}</p>" unless bullet?(group.first)

      "<ul>#{group.map { |item| "<li>#{inline_html(item).delete_prefix(BULLET).lstrip}</li>" }.join}</ul>"
    end

    # Joins a paragraph's lines. Wrapped lines usually keep their trailing space; add one when they don't,
    # unless the line ends in a hyphen or dash ("half-" + "dressed").
    def inline_html(para)
      html = para.first.html.dup
      para.each_cons(2) { |prev, line| html << (prev.text.match?(/[\s\-–—]\z/) ? '' : ' ') << line.html }
      html.gsub(/[ﬀ-ﬆ]/) { |ligature| ligature.unicode_normalize(:nfkc) }
          .gsub(%r{</b></i>(\s*)<i><b>}, '\1').gsub(%r{</(i|b)>(\s*)<\1>}, '\2') # italics split across lines
          .gsub(/ {2,}/, ' ').strip
    end
  end
end
