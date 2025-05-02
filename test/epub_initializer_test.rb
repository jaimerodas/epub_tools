require_relative 'test_helper'
require_relative '../lib/epub_tools/epub_initializer'

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
    EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest).run
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
    EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover).run
    # Check cover file and page
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.png'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, 'cover-image'
    assert_includes opf, '<item id="cover-page"'
    assert_includes opf, '<itemref idref="cover-page"'
  end

  def test_run_with_cover_jpg
    cover = File.join(@tmp, 'cover.jpg')
    File.write(cover, 'JPGDATA')
    EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover).run
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.jpg'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, "<item id=\"cover-image\" href=\"cover.jpg\" media-type=\"image/jpeg\""
    assert_includes opf, '<item id="cover-page"'
    assert_includes opf, '<itemref idref="cover-page"'
    cover_xhtml = File.read(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    assert_includes cover_xhtml, 'src="cover.jpg"'
  end

  def test_run_with_cover_jpeg
    cover = File.join(@tmp, 'cover.jpeg')
    File.write(cover, 'JPEGDATA')
    EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover).run
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.jpeg'))
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, "<item id=\"cover-image\" href=\"cover.jpeg\" media-type=\"image/jpeg\""
    cover_xhtml = File.read(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    assert_includes cover_xhtml, 'src="cover.jpeg"'
  end

  def test_run_with_cover_gif
    cover = File.join(@tmp, 'cover.gif')
    File.write(cover, 'GIFDATA')
    EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover).run
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.gif'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, "<item id=\"cover-image\" href=\"cover.gif\" media-type=\"image/gif\""
  end

  def test_run_with_cover_svg
    cover = File.join(@tmp, 'cover.svg')
    File.write(cover, '<svg/>')
    EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover).run
    assert File.exist?(File.join(@dest, 'OEBPS', 'cover.svg'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    assert_includes opf, "<item id=\"cover-image\" href=\"cover.svg\" media-type=\"image/svg+xml\""
  end

  def test_run_with_unsupported_cover_image
    cover = File.join(@tmp, 'cover.bmp')
    File.write(cover, 'BMPDATA')
    ei = EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover)
    assert_output("", /unsupported cover image type/) { ei.run }
    refute File.exist?(File.join(@dest, 'OEBPS', 'cover.bmp'))
    refute File.exist?(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    refute_includes opf, 'cover-image'
  end

  def test_run_without_cover_but_declaring_cover
    cover = File.join(@tmp, 'cover.bmp')
    ei = EpubTools::EpubInitializer.new(title: @title, author: @author, destination: @dest, cover_image: cover)
    assert_output("", /not found/) { ei.run }
    refute File.exist?(File.join(@dest, 'OEBPS', 'cover.xhtml'))
    opf = File.read(File.join(@dest, 'OEBPS', 'package.opf'))
    refute_includes opf, 'cover-image'
  end
end