# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/set_cover'
require_relative '../lib/epub_tools/epub_initializer'
require 'zip'

class SetCoverTest < Minitest::Test
  DC = { 'dc' => 'http://purl.org/dc/elements/1.1/' }.freeze

  def setup
    @tmp = Dir.mktmpdir
    @epub = File.join(@tmp, 'book.epub')
    book = EpubTools::EpubInitializer.new(title: 'Book', author: 'Me', destination: File.join(@tmp, 'book')).run
    EpubTools::PackEbook.new(input_dir: book, output_file: @epub).run
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_adds_then_replaces_the_cover_keeping_the_book_identity
    identifier = book_identifier
    apply_cover('art.png')
    apply_cover('art.jpg')

    assert_cover_entries('cover.jpg', 'image/jpeg')
    assert_cover_files('cover.jpg', replaced: 'cover.png')
    assert_equal identifier, book_identifier
    assert_path_exists "#{@epub}.bak"
  end

  def test_rejects_unsupported_image_types
    bmp = File.join(@tmp, 'art.bmp')
    File.write(bmp, 'BMP')

    error = assert_raises(ArgumentError) { EpubTools::SetCover.new(epub_file: @epub, cover_image: bmp) }
    assert_match(/unsupported cover image type/, error.message)
  end

  private

  def apply_cover(name)
    path = File.join(@tmp, name)
    File.write(path, 'IMAGE')
    EpubTools::SetCover.new(epub_file: @epub, cover_image: path).run
  end

  def assert_cover_entries(href, media_type)
    covers = opf.xpath('//xmlns:item[@properties="cover-image"]').map { |item| [item['href'], item['media-type']] }
    spine = opf.xpath('//xmlns:itemref').map { |ref| ref['idref'] }

    assert_equal [[href, media_type]], covers
    assert_equal %w[cover-page title], spine
    assert_equal 1, opf.xpath('//xmlns:meta[@name="cover"]').size
  end

  def assert_cover_files(image, replaced:)
    assert_includes zip_entry('OEBPS/cover.xhtml'), %(src="#{image}")
    refute_includes Zip::File.open(@epub) { |zip| zip.map(&:name) }, "OEBPS/#{replaced}"
  end

  def book_identifier = opf.at_xpath('//dc:identifier', DC).text

  def opf = Nokogiri::XML(zip_entry('OEBPS/package.opf'))

  def zip_entry(name) = Zip::File.open(@epub) { |zip| zip.read(name) }
end
