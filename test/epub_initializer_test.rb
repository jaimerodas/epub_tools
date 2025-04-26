require_relative 'test_helper'
require_relative '../epub_initializer'

class EpubInitializerTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @dest = File.join(@tmp, 'book_out')
    @title = 'My Title'
    @author = 'Me'
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_run_creates_basic_structure
    EpubInitializer.new(@title, @author, @dest).run
    # Check directories
    assert Dir.exist?(@dest)
    assert File.directory?(File.join(@dest, 'META-INF'))
    assert File.directory?(File.join(@dest, 'OEBPS'))
    # Check files
    mimetype = File.join(@dest, 'mimetype')
    assert File.exist?(mimetype)
    assert_equal 'application/epub+zip', File.read(mimetype)
    assert File.exist?(File.join(@dest, 'META-INF', 'container.xml'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'title.xhtml'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'nav.xhtml'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'package.opf'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'style.css'))
    # Check content of title.xhtml
    title_page = File.read(File.join(@dest, 'OEBPS', 'title.xhtml'))
    assert_includes title_page, "<h1 class=\"title\">#{@title}</h1>"
    assert_includes title_page, "<p class=\"author\">by #{@author}</p>"
    # Check package.opf metadata
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, "<dc:title>#{@title}</dc:title>"
    assert_includes opf, "<dc:creator>#{@author}</dc:creator>"
    refute_includes opf, 'cover.xhtml'
  end

  def test_run_with_cover_image
    # create dummy image
    cover = File.join(@tmp, 'cover.png')
    File.write(cover, 'PNGDATA')
    EpubInitializer.new(@title, @author, @dest, cover).run
    # Check cover file and page
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.png'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, 'cover-image'
    assert_includes opf, '<item id="cover-page"'
    assert_includes opf, '<itemref idref="cover-page"'
  end
end