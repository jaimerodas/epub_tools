# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/add_chapters'
require 'nokogiri'

class AddChaptersTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    # Directories for chapters and EPUB OEBPS
    @chapters_dir = File.join(@tmp, 'chapters')
    @epub_dir     = File.join(@tmp, 'OEBPS')
    Dir.mkdir(@chapters_dir)
    Dir.mkdir(@epub_dir)

    # Create sample chapter files
    @chap0 = File.join(@chapters_dir, 'chapter_0.xhtml')
    @chap1 = File.join(@chapters_dir, 'chapter_1.xhtml')
    File.write(@chap0, '<html><body><p>Prologue</p></body></html>')
    File.write(@chap1, '<html><body><p>First</p></body></html>')

    # Create minimal package.opf
    @opf_file = File.join(@epub_dir, 'package.opf')
    opf_content = <<~XML
      <?xml version="1.0"?>
      <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="en">
        <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        </metadata>
        <manifest>
        </manifest>
        <spine>
        </spine>
      </package>
    XML
    File.write(@opf_file, opf_content)

    # Create minimal nav.xhtml
    @nav_file = File.join(@epub_dir, 'nav.xhtml')
    nav_content = <<~XHTML
      <?xml version="1.0" encoding="utf-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
        <body>
          <nav epub:type="toc" id="toc">
            <ol>
            </ol>
          </nav>
        </body>
      </html>
    XHTML
    File.write(@nav_file, nav_content)
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_run_moves_files_and_updates_opf_and_nav
    result = EpubTools::AddChapters.new(chapters_dir: @chapters_dir, oebps_dir: @epub_dir).run

    verify_return_value(result)
    verify_files_moved
    verify_opf_structure
    verify_nav_structure
  end

  private

  def verify_return_value(result)
    assert_instance_of Array, result
    assert_equal 2, result.size
    assert_includes result, 'chapter_0.xhtml'
    assert_includes result, 'chapter_1.xhtml'
  end

  def verify_files_moved
    assert_empty Dir.glob(File.join(@chapters_dir, '*.xhtml'))
    assert_path_exists File.join(@epub_dir, 'chapter_0.xhtml')
    assert_path_exists File.join(@epub_dir, 'chapter_1.xhtml')
  end

  def verify_opf_structure
    doc = parse_opf_document
    opf_data = extract_opf_data(doc)

    assert_includes opf_data[:hrefs], 'chapter_0.xhtml'
    assert_includes opf_data[:hrefs], 'chapter_1.xhtml'
    assert_includes opf_data[:ids], 'chap0'
    assert_includes opf_data[:ids], 'chap1'
    assert_includes opf_data[:refs], 'chap0'
    assert_includes opf_data[:refs], 'chap1'
  end

  def verify_nav_structure
    links = extract_nav_links

    assert_equal 2, links.size
    assert_equal 'chapter_0.xhtml', links[0]['href']
    assert_equal 'Prologue', links[0].text
    assert_equal 'chapter_1.xhtml', links[1]['href']
    assert_equal 'Chapter 1', links[1].text
  end

  def parse_opf_document
    Nokogiri::XML(File.read(@opf_file)) { |cfg| cfg.default_xml.noblanks }
  end

  def extract_opf_data(doc)
    items = doc.xpath('//xmlns:manifest/xmlns:item')
    idrefs = doc.xpath('//xmlns:spine/xmlns:itemref')

    {
      hrefs: items.map { |i| i['href'] },
      ids: items.map { |i| i['id'] },
      refs: idrefs.map { |ir| ir['idref'] }
    }
  end

  def extract_nav_links
    nav_doc = Nokogiri::XML(File.read(@nav_file))
    nav_doc.remove_namespaces!
    nav_doc.xpath('//nav/ol/li/a')
  end
end
