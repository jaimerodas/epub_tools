# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/pdf_layout'

class PDFLayoutTest < Minitest::Test
  # Shaped like `pdftohtml -xml` output: body text at left=108, first-line indents at 135, lines 25px apart
  # and paragraphs 37px apart, with full lines ending at 800.
  XML = <<~XML
    <pdf2xml>
    <page number="1">
      <fontspec id="0" size="42"/><fontspec id="1" size="18"/>
      <text top="105" left="231" width="400" font="0">Chapter 1: Title in the PDF</text>
      <text top="198" left="135" width="200" font="1"><i><b>Monday, 9:00 am</b></i></text>
      <text top="231" left="135" width="600" font="1">The ﬁrst paragraph has <i>italic words that </i></text>
      <text top="256" left="108" width="692" font="1"><i>continue</i> on this line and ends with a half-</text>
      <text top="281" left="108" width="692" font="1">dressed word and no trailing space</text>
      <text top="306" left="108" width="600" font="1">before this line, which is full </text>
      <text top="306" left="708" width="92" font="1">width </text>
    </page>
    <page number="2">
      <text top="107" left="108" width="300" font="1">so it continues after the page break.</text>
      <text top="144" left="108" width="400" font="1">A block paragraph after a gap.</text>
      <text top="181" left="460" width="28" font="1">*** </text>
      <text top="218" left="135" width="665" font="1">After the break, a paragraph whose writer hit</text>
      <text top="255" left="135" width="200" font="1">enter by mistake.</text>
      <text top="292" left="135" width="100" font="1">Short end.</text>
    </page>
    <page number="3">
      <text top="107" left="108" width="400" font="1">A new paragraph, as the last page ended short.</text>
      <text top="144" left="126" width="300" font="1">• A bullet that wraps</text>
      <text top="164" left="138" width="200" font="1">onto a second line</text>
      <text top="184" left="126" width="200" font="1">• Second bullet</text>
    </page>
    </pdf2xml>
  XML

  def test_rebuilds_paragraphs
    html = EpubTools::PDFLayout.new(Nokogiri::XML(XML)).to_html

    assert_equal [
      '<p><i><b>Monday, 9:00 am</b></i></p>',
      '<p>The first paragraph has <i>italic words that continue</i> on this line and ends with a half-dressed ' \
      'word and no trailing space before this line, which is full width so it continues after the page break.</p>',
      '<p>A block paragraph after a gap.</p>',
      '<hr/>',
      '<p>After the break, a paragraph whose writer hit enter by mistake.</p>',
      '<p>Short end.</p>',
      '<p>A new paragraph, as the last page ended short.</p>',
      '<ul><li>A bullet that wraps onto a second line</li><li>Second bullet</li></ul>'
    ], html.split("\n    ")
  end

  def test_empty_without_body_text
    assert_predicate EpubTools::PDFLayout.new(Nokogiri::XML('<pdf2xml><page number="1"/></pdf2xml>')), :empty?
  end
end
