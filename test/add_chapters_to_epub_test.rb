require_relative 'test_helper'
require_relative '../add_chapters_to_epub'
require 'nokogiri'

class AddChaptersToEpubTest < Minitest::Test
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
    # Run the add chapters task
    AddChaptersToEpub.new(@chapters_dir, @epub_dir).run

    # Original chapter files should be moved
    assert_empty Dir.glob(File.join(@chapters_dir, '*.xhtml'))
    assert File.exist?(File.join(@epub_dir, 'chapter_0.xhtml'))
    assert File.exist?(File.join(@epub_dir, 'chapter_1.xhtml'))

    # package.opf should include manifest items and spine refs
    doc = Nokogiri::XML(File.read(@opf_file)) { |cfg| cfg.default_xml.noblanks }
    items   = doc.xpath('//xmlns:manifest/xmlns:item')
    idrefs  = doc.xpath('//xmlns:spine/xmlns:itemref')
    hrefs   = items.map { |i| i['href'] }
    ids     = items.map { |i| i['id'] }
    refs    = idrefs.map { |ir| ir['idref'] }

    assert_includes hrefs, 'chapter_0.xhtml'
    assert_includes hrefs, 'chapter_1.xhtml'
    assert_includes ids,   'chap0'
    assert_includes ids,   'chap1'
    assert_includes refs,  'chap0'
    assert_includes refs,  'chap1'

    # nav.xhtml should have list entries for each chapter
    nav_doc = Nokogiri::XML(File.read(@nav_file))
    # strip namespaces for easy querying
    nav_doc.remove_namespaces!
    links = nav_doc.xpath('//nav/ol/li/a')
    assert_equal 2, links.size
    # First is Prologue (chapter_0)
    assert_equal 'chapter_0.xhtml', links[0]['href']
    assert_equal 'Prologue',          links[0].text
    # Second is Chapter 1
    assert_equal 'chapter_1.xhtml', links[1]['href']
    assert_equal 'Chapter 1',         links[1].text
  end
end