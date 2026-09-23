# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/pdf_converter'

class PDFConverterTest < Minitest::Test
  XML = <<~XML
    <pdf2xml><page number="1">
      <fontspec id="0" size="42"/><fontspec id="1" size="18"/>
      <text top="105" left="231" width="400" font="0">Heading typed in the PDF</text>
      <text top="198" left="135" width="400" font="1">Tom &amp; Jerry’s text.</text>
      <text top="235" left="135" width="400" font="1">More text.</text>
    </page></pdf2xml>
  XML

  def setup
    @tmp = Dir.mktmpdir
    @source = File.join(@tmp, 'pdfs')
    @output = File.join(@tmp, 'chapters')
    FileUtils.mkdir_p(@source)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_names_chapters_after_their_pdfs
    ['0 Cast List.pdf', "12a Don't Stop.pdf"].each { |name| FileUtils.touch(File.join(@source, name)) }

    paths = converter.run

    assert_equal %w[chapter_0.xhtml chapter_12a.xhtml], paths.map { |path| File.basename(path) }.sort
    assert_equal 'Cast List', heading('chapter_0.xhtml')
    assert_equal 'Chapter 12a: Don’t Stop', heading('chapter_12a.xhtml')
    assert_includes File.read(File.join(@output, 'chapter_12a.xhtml')), '<p>Tom &amp; Jerry’s text.</p>'
  end

  def test_rejects_pdfs_without_a_chapter_number
    FileUtils.touch(File.join(@source, 'Epilogue.pdf'))

    error = assert_raises(ArgumentError) { converter.run }
    assert_match(/Epilogue\.pdf/, error.message)
  end

  def test_does_nothing_without_pdfs
    assert_empty converter.run
    refute_path_exists @output
  end

  private

  def converter
    xml = XML
    EpubTools::PDFConverter.new(source_dir: @source, output_dir: @output, book_title: 'Book').tap do |converter|
      converter.define_singleton_method(:pdftohtml) { |_pdf| Nokogiri::XML(xml) }
    end
  end

  def heading(file)
    Nokogiri::XML(File.read(File.join(@output, file))).at_xpath('//xmlns:h1').text
  end
end
